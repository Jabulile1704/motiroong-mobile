import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
  bool _busy = false;
  bool _clockedIn = false;
  DateTime? _clockInTime;
  Timer? _ticker;

  // Demo weekly hours (Mon..Sun) until the attendance repository lands.
  static const List<double> _weekHours = [6.5, 8, 4.7, 0, 0, 0, 0];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _toggleClock() async {
    setState(() => _busy = true);
    // Placeholder for the real attendance repository call
    // (location check + API request + offline queue).
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _clockedIn = !_clockedIn;
      _clockInTime = _clockedIn ? DateTime.now() : null;
    });
    // Keep the elapsed time live while clocked in.
    _ticker?.cancel();
    if (_clockedIn) {
      _ticker = Timer.periodic(
        const Duration(minutes: 1),
        (_) => setState(() {}),
      );
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
          _StatusCard(clockedIn: _clockedIn, since: _clockInTime),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: ClockButton(
                clockedIn: _clockedIn,
                busy: _busy,
                onPressed: _toggleClock,
              ),
            ),
          ),
          BrandCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel("Today's shift"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '9:00 AM – 5:00 PM',
                      style: TextStyle(
                        fontFamily: Brand.wordmarkFont,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                    const StatusPill('Front Desk'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('This week'),
          const SizedBox(height: 10),
          _WeekChart(hours: _weekHours, today: now.weekday - 1),
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
