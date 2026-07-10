import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/moti_icons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// History, per the app-screens handoff: day-grouped activity log rows
/// with fill/outline status chips; flagged entries (late) get a dark
/// outline instead of color.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final List<(String, List<_HistoryEntry>)> groups = _demoGroups();

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
          const SectionEyebrow('Activity log'),
          const SizedBox(height: 6),
          const ScreenTitle('History'),
          const SizedBox(height: 20),
          for (final (String day, List<_HistoryEntry> entries) in groups) ...[
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
            for (final _HistoryEntry e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryRow(entry: e),
              ),
          ],
        ],
      ),
    );
  }

  /// Demo data mirroring the handoff, relative to the current date,
  /// until the attendance repository is wired up.
  static List<(String, List<_HistoryEntry>)> _demoGroups() {
    final DateTime twoBack = DateTime.now().subtract(const Duration(days: 2));

    return [
      (
        'Today',
        const [
          _HistoryEntry(title: 'Clocked in', sub: '9:02 AM', chip: 'On time'),
        ],
      ),
      (
        'Yesterday',
        const [
          _HistoryEntry(title: 'Clocked out', sub: '7:00 PM', chip: '7h 58m'),
          _HistoryEntry(
            title: 'Clocked in',
            sub: '9:41 AM',
            chip: 'Late',
            flagged: true,
          ),
        ],
      ),
      (
        DateFormatter.dayLabel(twoBack),
        const [
          _HistoryEntry(
            title: 'Clocked in / out',
            sub: '9:00 AM – 5:04 PM',
            chip: '8h 04m',
          ),
          _HistoryEntry(
            title: 'Clocked in / out',
            sub: '9:01 AM – 5:00 PM',
            chip: '7h 59m',
          ),
        ],
      ),
    ];
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.title,
    required this.sub,
    required this.chip,
    this.flagged = false,
  });

  final String title;
  final String sub;
  final String chip;
  final bool flagged;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: entry.flagged ? p.flaggedBorder : p.hairline),
      ),
      child: Row(
        children: [
          IconBadge(
            glyph: MotiGlyph.clock,
            size: 36,
            iconSize: 18,
            radius: 10,
            border: entry.flagged ? Border.all(color: p.ink, width: 1.5) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.sub,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 12,
                    color: p.muted,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            entry.chip,
            style: entry.flagged
                ? StatusPillStyle.outlined
                : StatusPillStyle.filled,
          ),
        ],
      ),
    );
  }
}
