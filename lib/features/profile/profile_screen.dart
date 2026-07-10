import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/moti_icons.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/settings_row.dart';
import '../auth/presentation/providers/auth_provider.dart';

/// Profile, per the app-screens handoff: centered identity block and
/// labeled card groups (Contact / Account / Preferences / Support) built
/// from the reusable SettingsRow, plus the outlined Log Out action.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    final String name = authProvider.session?.fullName ?? 'Jordan Silva';
    final String initials = authProvider.session?.initials ?? 'JS';
    final String role = authProvider.session?.role ?? 'Front Desk';
    final String employeeId =
        authProvider.session?.employeeId.replaceAll('EMP-', '') ?? '4021';
    final String email =
        '${name.toLowerCase().replaceAll(' ', '.')}@motiroong.com';

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
          const ScreenHeader(),
          const SizedBox(height: 26),
          const SectionEyebrow('Account'),
          const SizedBox(height: 6),
          const ScreenTitle('Profile'),
          const SizedBox(height: 22),

          // Identity block.
          Column(
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: p.onInk,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  fontFamily: Brand.wordmarkFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$role · ID $employeeId',
                style: TextStyle(
                  fontFamily: Brand.taglineFont,
                  fontSize: 11,
                  color: p.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const SectionLabel('Contact'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              _ContactRow(glyph: MotiGlyph.mail, label: 'Email', value: email),
              const _ContactRow(
                glyph: MotiGlyph.phone,
                label: 'Phone',
                value: '(555) 019-2244',
              ),
            ],
          ),
          const SizedBox(height: 22),

          const SectionLabel('Account'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              SettingsRow(
                glyph: MotiGlyph.person,
                label: 'Personal Information',
                onTap: () {},
              ),
              SettingsRow(
                glyph: MotiGlyph.fingerprint,
                label: 'Devices & Biometrics',
                onTap: () {},
              ),
              SettingsRow(
                glyph: MotiGlyph.pin,
                label: 'Location Permissions',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 22),

          const SectionLabel('Preferences'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              SettingsRow(
                glyph: MotiGlyph.appearance,
                label: 'Appearance',
                value: 'System',
                onTap: () {},
              ),
              SettingsRow(
                glyph: MotiGlyph.shield,
                label: 'Notifications',
                showChevron: false,
                trailing: _BrandSwitch(
                  value: _notificationsOn,
                  onChanged: (v) => setState(() => _notificationsOn = v),
                ),
                onTap: () =>
                    setState(() => _notificationsOn = !_notificationsOn),
              ),
            ],
          ),
          const SizedBox(height: 22),

          const SectionLabel('Support'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              SettingsRow(
                glyph: MotiGlyph.help,
                label: 'Help & Support',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Outlined log out — deliberately quieter than filled actions.
          GestureDetector(
            onTap: () => _confirmSignOut(context),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: p.ink, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: Brand.wordmarkFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to clock in.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              authProvider.signOut();
              // Back to login, clearing the whole navigation stack.
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

/// White card that groups rows with hairline separators between them.
class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: p.rowHairline),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Contact row: icon badge + uppercase mono label above the value.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.glyph,
    required this.label,
    required this.value,
  });

  final MotiGlyph glyph;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconBadge(glyph: glyph),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: Brand.taglineFont,
                    fontSize: 10,
                    letterSpacing: Brand.emSpacing(10, 0.1),
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 14,
                    color: p.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom monochrome switch (42×25, ink track) per the handoff.
class _BrandSwitch extends StatelessWidget {
  const _BrandSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 42,
        height: 25,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: value ? p.ink : p.field,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? p.onInk : p.muted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
