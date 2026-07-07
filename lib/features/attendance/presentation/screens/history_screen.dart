import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/attendance_record.dart';

/// History tab: attendance records in iOS inset-grouped list style.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Demo data until the attendance repository is wired up.
  static final List<AttendanceRecord> _records = List.generate(7, (i) {
    final DateTime day = DateTime.now().subtract(Duration(days: i));
    final DateTime clockIn = DateTime(day.year, day.month, day.day, 8, 2 + i);
    return AttendanceRecord(
      id: 'rec-$i',
      clockIn: clockIn,
      clockOut:
          i == 0 ? null : clockIn.add(const Duration(hours: 8, minutes: 12)),
      location: 'Head Office',
    );
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('History')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            20, 8, 20, AppConstants.bottomBarClearance),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'THIS WEEK',
              style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
            ),
          ),
          // Inset grouped card: rounded container, hairline separators.
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Card(
              shape: const RoundedRectangleBorder(),
              child: Column(
                children: [
                  for (int i = 0; i < _records.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Divider(),
                      ),
                    _RecordRow(record: _records[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    final String times = record.isComplete
        ? '${DateFormatter.time(record.clockIn)} – '
            '${DateFormatter.time(record.clockOut!)}'
        : 'In at ${DateFormatter.time(record.clockIn)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            record.isComplete
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.clock_fill,
            size: 28,
            color: record.isComplete
                ? AppColors.success(brightness)
                : AppColors.warning(brightness),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.dayLabel(record.clockIn),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(times, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          record.isComplete
              ? Text(
                  DateFormatter.duration(record.workedDuration),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              : StatusBadge(
                  label: 'Active',
                  color: AppColors.success(brightness),
                ),
        ],
      ),
    );
  }
}
