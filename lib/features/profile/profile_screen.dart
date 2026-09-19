import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/moti_icons.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/settings_row.dart';
import '../attendance/presentation/providers/attendance_provider.dart';
import '../auth/data/models/auth_response.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../auth/presentation/screens/device_enrollment_screen.dart';

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
  void initState() {
    super.initState();
    authProvider.addListener(_changed);
    attendanceProvider.addListener(_changed);
    if (attendanceProvider.siteNames.isEmpty) attendanceProvider.loadSites();
    // Pick up anything HR changed (department, site) since sign-in.
    authProvider.refreshProfile();
  }

  @override
  void dispose() {
    authProvider.removeListener(_changed);
    attendanceProvider.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    final AuthResponse? me = authProvider.session;
    final String name = me?.fullName ?? '';
    final String initials = me?.initials ?? '';
    final String role = me?.roleLabel ?? 'Employee';
    final String employeeId = me?.employeeId ?? '—';
    final String email = me?.email ?? '—';
    final String? phone = (me?.phone?.isNotEmpty ?? false) ? me!.phone : null;
    final String? siteName = me?.siteId == null
        ? null
        : attendanceProvider.siteNames[me!.siteId] ?? me.siteId;

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
              _ContactRow(
                glyph: MotiGlyph.phone,
                label: 'Phone',
                value: phone ?? 'Add your phone number',
                muted: phone == null,
                actionLabel: phone == null ? 'Add' : 'Edit',
                onTap: () => _editPhone(context, phone),
              ),
            ],
          ),
          const SizedBox(height: 22),

          const SectionLabel('Work'),
          const SizedBox(height: 8),
          _CardGroup(
            children: [
              _ContactRow(
                glyph: MotiGlyph.person,
                label: 'Department',
                value: me?.department?.isNotEmpty == true
                    ? me!.department!
                    : 'Not set',
                muted: me?.department?.isNotEmpty != true,
              ),
              _ContactRow(
                glyph: MotiGlyph.pin,
                label: 'Home site',
                value: siteName ?? 'Not assigned yet',
                muted: siteName == null,
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
                label: 'Face ID, Fingerprint or PIN',
                value: me?.biometricEnrolled == true ? 'On' : 'Off',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) =>
                        const DeviceEnrollmentScreen(fromSignUp: false),
                  ),
                ),
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

  /// Phone editor: a sheet with one field, saved through `updateMyProfile`.
  Future<void> _editPhone(BuildContext context, String? current) async {
    final String? saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhoneSheet(initial: current ?? ''),
    );
    if (saved != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Phone number saved: $saved')));
    }
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
              unawaited(authProvider.signOut());
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
    this.muted = false,
    this.actionLabel,
    this.onTap,
  });

  final MotiGlyph glyph;
  final String label;
  final String value;

  /// Placeholder text ("Add your phone number") rather than a real value.
  final bool muted;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    final Widget row = Padding(
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
                    color: muted ? p.muted : p.ink,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Text(
              actionLabel!,
              style: TextStyle(
                fontFamily: Brand.wordmarkFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: '$label: $value. ${actionLabel ?? ''}',
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Bottom sheet for adding or changing the phone number.
class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet({required this.initial});

  final String initial;

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final String? error = await authProvider.updatePhone(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(
        context,
      ).pop(authProvider.session?.phone ?? _controller.text);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Phone number',
                style: TextStyle(
                  fontFamily: Brand.wordmarkFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your supervisor uses this to reach you about your shifts.',
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  hintText: 'e.g. 082 555 1234',
                  errorText: _error,
                  fillColor: p.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: p.ink,
                  foregroundColor: p.onInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? CupertinoActivityIndicator(color: p.onInk)
                    : const Text('Save'),
              ),
            ],
          ),
        ),
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
