import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/attendance_record.dart';
import '../providers/attendance_provider.dart';
import '../widgets/clock_button.dart';

/// Home, per the app-screens handoff: date eyebrow + greeting, the dark
/// status card with the live elapsed time, the 132px clock action, the
/// shift card and the weekly bar chart.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    attendanceProvider.addListener(_onAttendanceChanged);
    attendanceProvider.refresh();
    // History feeds the weekly chart and today's total; sites name the card.
    attendanceProvider.loadHistory();
    attendanceProvider.loadSites();
    // Keep the elapsed time live while clocked in.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (attendanceProvider.isClockedIn) setState(() {});
    });
  }

  @override
  void dispose() {
    attendanceProvider.removeListener(_onAttendanceChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _onAttendanceChanged() {
    if (mounted) setState(() {});
  }

  /// The server decides the verdict; this only reports it.
  Future<void> _toggleClock() async {
    final ClockResult? result = attendanceProvider.isClockedIn
        ? await attendanceProvider.clockOut()
        : await attendanceProvider.clockIn();
    if (!mounted) return;

    final String? error = attendanceProvider.error;
    final String? message = result == null
        ? error
        : result.isFlagged
        ? 'Recorded, but flagged: ${result.flags.map((f) => f.name).join(', ')}'
        : result.siteName != null
        ? 'Recorded at ${result.siteName}'
        : null;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final DateTime now = DateTime.now();
    final String firstName =
        authProvider.session?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: p.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 14,
          20,
          108,
        ),
        children: [
          ScreenHeader(initials: authProvider.session?.initials ?? 'JS'),
          const SizedBox(height: 26),
          SectionEyebrow(DateFormatter.eyebrowDate(now)),
          const SizedBox(height: 6),
          ScreenTitle('${DateFormatter.greeting(now)}, $firstName'),
          const SizedBox(height: 22),
          _StatusCard(
            clockedIn: attendanceProvider.isClockedIn,
            since: attendanceProvider.state.since?.toLocal(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: ClockButton(
                clockedIn: attendanceProvider.isClockedIn,
                busy: attendanceProvider.isBusy,
                onPressed: _toggleClock,
              ),
            ),
          ),
          _TodayCard(now: now),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('This week'),
              Text(
                '${_weekTotal(now).toStringAsFixed(1)} h',
                style: TextStyle(
                  fontFamily: Brand.taglineFont,
                  fontSize: 11,
                  color: p.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WeekChart(hours: _weekHours(now), today: now.weekday - 1),
        ],
      ),
    );
  }
}

/// Hours worked on each day of the current week (Monday first), from the
/// employee's own shifts. An open shift counts up to now.
List<double> _weekHours(DateTime now) {
  final DateTime monday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final List<double> hours = List<double>.filled(7, 0);
  for (final AttendanceRecord r in attendanceProvider.history) {
    final DateTime start = r.clockInAt;
    final int index = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(monday).inDays;
    if (index < 0 || index > 6) continue;
    hours[index] += r.workedDuration.inMinutes / 60;
  }
  return hours;
}

double _weekTotal(DateTime now) => _weekHours(now).fold(0, (a, b) => a + b);

/// Today at a glance: time worked so far and where. Replaces the handoff's
/// fixed "9:00 AM – 5:00 PM" card — the backend records shifts, not rosters,
/// so there is no scheduled shift to show.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final DateTime midnight = DateTime(now.year, now.month, now.day);
    final List<AttendanceRecord> today = attendanceProvider.history
        .where((r) => !r.clockInAt.isBefore(midnight))
        .toList();
    final Duration worked = today.fold(
      Duration.zero,
      (total, r) => total + r.workedDuration,
    );

    // Where: the open shift's site, else the home site HR assigned.
    final String? siteId =
        attendanceProvider.state.siteId ?? authProvider.session?.siteId;
    final String site = siteId == null
        ? 'No site yet'
        : attendanceProvider.siteNames[siteId] ?? 'Your site';

    final String headline = today.isEmpty
        ? 'Not clocked in yet'
        : '${DateFormatter.duration(worked)} worked';
    final String detail = today.isEmpty
        ? 'Tap the button above to start your shift.'
        : 'First in at ${DateFormatter.time12(today.last.clockInAt)}'
              '${today.length > 1 ? ' · ${today.length} shifts' : ''}';

    return BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Today'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: StatusPill(site)),
            ],
          ),
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(fontSize: 12, color: p.muted)),
        ],
      ),
    );
  }
}

/// Dark status card: live dot + CLOCKED IN/OUT, since-time, and the big
/// elapsed figure.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.clockedIn, this.since});

  final bool clockedIn;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final Duration worked = since != null
        ? DateTime.now().difference(since!)
        : Duration.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: clockedIn ? Brand.offWhite : Brand.mutedGrey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    clockedIn ? 'CLOCKED IN' : 'CLOCKED OUT',
                    style: TextStyle(
                      fontFamily: Brand.taglineFont,
                      fontSize: 11,
                      letterSpacing: Brand.emSpacing(11, 0.14),
                      color: Brand.offWhite,
                    ),
                  ),
                ],
              ),
              if (since != null)
                Text(
                  'since ${DateFormatter.time12(since!)}',
                  style: const TextStyle(
                    fontFamily: Brand.taglineFont,
                    fontSize: 11,
                    color: Brand.lightGrey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            DateFormatter.duration(
              worked,
            ).replaceFirstMapped(RegExp(r'^(\d+)m$'), (m) => '0h ${m[1]}m'),
            style: TextStyle(
              fontFamily: Brand.wordmarkFont,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: Brand.emSpacing(42, -0.02),
              color: Brand.offWhite,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Worked today',
            style: TextStyle(
              fontFamily: Brand.wordmarkFont,
              fontSize: 13,
              color: Brand.lightGrey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-bar Mon–Sun chart: ink bars for logged days, field-grey bars
/// for the rest, today's label bolded.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.hours, required this.today});

  final List<double> hours;
  final int today; // 0 = Monday

  static const List<String> _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const double _maxBar = 64;
  static const double _minBar = 8;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return BrandCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: hours[i] <= 0
                        ? _minBar
                        : _minBar +
                              (hours[i] / 8).clamp(0, 1) * (_maxBar - _minBar),
                    constraints: const BoxConstraints(maxWidth: 20),
                    decoration: BoxDecoration(
                      // Completed days are ink; today and future stay light.
                      color: hours[i] > 0 && i < today ? p.ink : p.field,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 10,
                      fontWeight: i == today
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: i == today ? p.ink : p.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
