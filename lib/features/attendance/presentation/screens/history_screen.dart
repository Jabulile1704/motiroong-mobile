import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/moti_icons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/attendance_record.dart';
import '../providers/attendance_provider.dart';

/// History, per the app-screens handoff: day-grouped activity log rows with
/// fill/outline status chips. Rows are the employee's own shifts from
/// `getAttendanceHistory`; a flagged shift gets the dark outline and its flag
/// labels ("Off site", "Weak GPS"…), never a colour.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    attendanceProvider.addListener(_changed);
    if (!attendanceProvider.historyLoaded) attendanceProvider.loadHistory();
    if (attendanceProvider.siteNames.isEmpty) attendanceProvider.loadSites();
  }

  @override
  void dispose() {
    attendanceProvider.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await attendanceProvider.loadMoreHistory();
    if (mounted) setState(() => _loadingMore = false);
  }

  /// Shifts grouped under "Today", "Yesterday", "Mon, Sep 15"…
  static List<(String, List<AttendanceRecord>)> _group(
    List<AttendanceRecord> records,
  ) {
    final List<(String, List<AttendanceRecord>)> groups = [];
    for (final AttendanceRecord r in records) {
      final String day = DateFormatter.dayLabel(r.clockInAt);
      if (groups.isEmpty || groups.last.$1 != day) {
        groups.add((day, <AttendanceRecord>[]));
      }
      groups.last.$2.add(r);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final List<AttendanceRecord> history = attendanceProvider.history;
    final bool loaded = attendanceProvider.historyLoaded;

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        color: p.ink,
        onRefresh: attendanceProvider.loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 14,
            20,
            108,
          ),
          children: [
            ScreenHeader(initials: authProvider.session?.initials),
            const SizedBox(height: 26),
            const SectionEyebrow('Activity log'),
            const SizedBox(height: 6),
            const ScreenTitle('History'),
            const SizedBox(height: 20),
            if (!loaded)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (history.isEmpty)
              _EmptyState(error: attendanceProvider.error)
            else ...[
              for (final (String day, List<AttendanceRecord> shifts) in _group(
                history,
              )) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 8),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                ),
                for (final AttendanceRecord r in shifts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryRow(
                      record: r,
                      siteName: r.siteId == null
                          ? null
                          : attendanceProvider.siteNames[r.siteId],
                    ),
                  ),
              ],
              if (attendanceProvider.hasMoreHistory)
                Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CupertinoActivityIndicator(),
                        )
                      : TextButton(
                          onPressed: _loadMore,
                          child: Text(
                            'Load earlier shifts',
                            style: TextStyle(color: p.ink),
                          ),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return BrandCard(
      child: Column(
        children: [
          IconBadge(glyph: MotiGlyph.clock, size: 44, iconSize: 22),
          const SizedBox(height: 12),
          Text(
            error ?? 'No shifts yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Brand.wordmarkFont,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
          if (error == null) ...[
            const SizedBox(height: 4),
            Text(
              'Clock in from Home and your shifts will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, this.siteName});

  final AttendanceRecord record;
  final String? siteName;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final AttendanceRecord r = record;
    final bool flagged = r.isFlagged;

    final String title = r.isOpen ? 'On shift' : 'Clocked in / out';
    final String times = r.isOpen
        ? 'Since ${DateFormatter.time12(r.clockInAt)}'
        : '${DateFormatter.time12(r.clockInAt)} – '
              '${r.clockOutAt != null ? DateFormatter.time12(r.clockOutAt!) : '—'}';
    final String sub = [times, if (siteName != null) siteName!].join(' · ');
    final String flags = r.flags.map((f) => f.label).toSet().join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: flagged ? p.flaggedBorder : p.hairline),
      ),
      child: Row(
        children: [
          IconBadge(
            glyph: MotiGlyph.clock,
            size: 36,
            iconSize: 18,
            radius: 10,
            border: flagged ? Border.all(color: p.ink, width: 1.5) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 12,
                    color: p.muted,
                  ),
                ),
                if (flags.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    flags,
                    style: TextStyle(
                      fontFamily: Brand.taglineFont,
                      fontSize: 10,
                      color: p.ink,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            r.isOpen ? 'Live' : DateFormatter.duration(r.workedDuration),
            style: r.isOpen
                ? StatusPillStyle.inverse
                : flagged
                ? StatusPillStyle.outlined
                : StatusPillStyle.filled,
          ),
        ],
      ),
    );
  }
}
