import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Profile tab: iOS Settings-style grouped lists with tinted icon tiles.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            20, 8, 20, AppConstants.bottomBarClearance),
        children: [
          // Identity header.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Text(
                      'JM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jabulile M.', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text('Employee · Head Office',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: CupertinoIcons.person_fill,
                iconColor: AppColors.primary(brightness),
                label: 'Personal information',
                onTap: () {},
              ),
              _SettingsRow(
                icon: CupertinoIcons.lock_shield_fill,
                iconColor: AppColors.success(brightness),
                label: 'Device & biometrics',
                onTap: () {},
              ),
              _SettingsRow(
                icon: CupertinoIcons.location_solid,
                iconColor: AppColors.warning(brightness),
                label: 'Location permissions',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SettingsGroup(
            children: [
              _SettingsRow(
                icon: CupertinoIcons.moon_fill,
                iconColor: brightness == Brightness.dark
                    ? AppColors.infoDark
                    : AppColors.infoLight,
                label: 'Appearance',
                detail: 'System',
                onTap: () {},
              ),
              _SettingsRow(
                icon: CupertinoIcons.question_circle_fill,
                iconColor: brightness == Brightness.dark
                    ? AppColors.tealDark
                    : AppColors.tealLight,
                label: 'Help & support',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          Card(
            child: ListTile(
              title: Center(
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 17,
                    letterSpacing: -0.41,
                    color: AppColors.danger(brightness),
                  ),
                ),
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded card grouping settings rows with hairline separators,
/// mirroring iOS inset-grouped table sections.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Card(
        shape: const RoundedRectangleBorder(),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.only(left: 60),
                  child: Divider(),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detail != null)
            Text(
              detail!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryLabel(brightness),
              ),
            ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 18,
            color: AppColors.secondaryLabel(brightness),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
