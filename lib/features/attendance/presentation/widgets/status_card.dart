import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/attendance_record.dart';

/// Inset grouped card showing the current clock status, the time the
/// shift started, and the verified location.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.status,
    this.since,
    this.location,
  });

  final ClockStatus status;
  final DateTime? since;
  final String? location;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    final Color statusColor = switch (status) {
      ClockStatus.clockedIn => AppColors.success(brightness),
      ClockStatus.clockedOut => AppColors.secondaryLabel(brightness),
      ClockStatus.onBreak => AppColors.warning(brightness),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current status', style: theme.textTheme.titleMedium),
                StatusBadge(label: status.label, color: statusColor),
              ],
            ),
            if (since != null || location != null) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 6),
            ],
            if (since != null)
              _InfoRow(
                icon: CupertinoIcons.time,
                label: 'Since',
                value: DateFormatter.time(since!),
              ),
            if (location != null)
              _InfoRow(
                icon: CupertinoIcons.location_solid,
                label: 'Location',
                value: location!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
