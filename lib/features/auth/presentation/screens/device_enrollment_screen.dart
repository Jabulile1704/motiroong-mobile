import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/brand.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';
import '../providers/auth_provider.dart';
import '../widgets/staff_card.dart';
import 'pin_setup_screen.dart';

/// "Seal it to this phone" — step 2 of sign-up (design direction C).
///
/// The employee chooses how they will sign in on this phone: the OS
/// biometric (Face ID on iPhone, fingerprint on Android) or a 6-digit PIN.
/// Either way `enrollDevice` binds this phone to the account; see
/// [AuthRepository.enrollQuickSignIn] for what the server does and does not
/// learn.
///
/// With [fromSignUp] the screen routes onward when done (to the approval
/// screen or home); otherwise it pops `true`, so Settings can reuse it.
class DeviceEnrollmentScreen extends StatefulWidget {
  const DeviceEnrollmentScreen({super.key, this.fromSignUp = true});

  final bool fromSignUp;

  @override
  State<DeviceEnrollmentScreen> createState() => _DeviceEnrollmentScreenState();
}

class _DeviceEnrollmentScreenState extends State<DeviceEnrollmentScreen> {
  BiometricAvailability? _availability;
  BiometricKind _kind = BiometricKind.none;
  QuickSignIn _choice = QuickSignIn.biometric;
  bool _busy = false;
  bool _sealed = false;

  bool get _biometricReady => _availability == BiometricAvailability.ready;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final BiometricAvailability availability =
        await authProvider.biometricAvailability;
    final BiometricKind kind = await authProvider.biometricKind;
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _kind = kind;
      if (availability != BiometricAvailability.ready) {
        _choice = QuickSignIn.pin;
      }
    });
  }

  /// "Face ID" on iPhone, "Fingerprint" on most Android phones.
  String get _biometricTitle =>
      _kind == BiometricKind.none ? 'Face ID' : _kind.title;

  String get _biometricSubtitle => switch (_availability) {
    BiometricAvailability.ready =>
      'Your face or finger never leaves this phone',
    BiometricAvailability.notEnrolled =>
      'Set it up in your phone’s Settings first',
    BiometricAvailability.lockedOut => 'Locked — unlock your phone, then retry',
    BiometricAvailability.unsupported => 'Not available on this phone',
    null => 'Checking this phone…',
  };

  Future<void> _seal() async {
    String? pin;
    if (_choice == QuickSignIn.pin) {
      pin = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(builder: (_) => const PinSetupScreen()),
      );
      if (pin == null || !mounted) return;
    }

    setState(() => _busy = true);
    final bool ok = await authProvider.enrollQuickSignIn(_choice, pin: pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sealed = ok;
    });

    if (!ok) {
      final String? error = authProvider.enrollError;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    // Let the seal land on the card before moving on.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) _finish(true);
  }

  void _finish(bool enrolled) {
    if (widget.fromSignUp) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(authProvider.homeRoute, (_) => false);
    } else {
      Navigator.of(context).pop(enrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final AuthResponse? session = authProvider.session;
    final String sealLabel = _choice == QuickSignIn.pin
        ? 'PIN'
        : _biometricTitle.toUpperCase();

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // No back button from sign-up: the account already exists, and
                // going back to the form would only create confusion.
                if (!widget.fromSignUp)
                  IconButton(
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(CupertinoIcons.back, color: p.ink),
                  )
                else
                  const SizedBox(height: 48),
                if (widget.fromSignUp) const SectionEyebrow('2 / 2'),
              ],
            ),
            const SizedBox(height: 8),
            StaffCard(
              name: session?.fullName ?? '',
              employeeId: session?.employeeId,
              department: session?.department,
              status: session?.status.label.toUpperCase() ?? 'PENDING APPROVAL',
              slotLabel: _sealed ? sealLabel : 'SIGN-IN',
              slotValue: _sealed ? 'SEALED TO THIS PHONE' : 'CHOOSE BELOW',
              sealed: _sealed,
            ),
            const SizedBox(height: 22),
            const ScreenTitle('Seal it to this phone'),
            const SizedBox(height: 6),
            Text(
              'This is how you’ll sign in and clock in. Only this phone can use it.',
              style: TextStyle(fontSize: 14, height: 1.45, color: p.muted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MethodTile(
                    selected: _choice == QuickSignIn.biometric,
                    enabled: _biometricReady,
                    icon: _kind == BiometricKind.fingerprint
                        ? Icons.fingerprint
                        : CupertinoIcons.viewfinder,
                    title: _biometricTitle,
                    subtitle: _biometricSubtitle,
                    onTap: () =>
                        setState(() => _choice = QuickSignIn.biometric),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MethodTile(
                    selected: _choice == QuickSignIn.pin,
                    enabled: true,
                    icon: CupertinoIcons.circle_grid_3x3_fill,
                    title: 'PIN',
                    subtitle: '6 digits, any phone',
                    onTap: () => setState(() => _choice = QuickSignIn.pin),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            LoadingButton(
              label: _choice == QuickSignIn.pin
                  ? 'Seal with a PIN'
                  : 'Seal with $_biometricTitle',
              loading: _busy,
              onPressed: _sealed ? null : _seal,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _busy ? null : () => _finish(false),
              child: Text(
                widget.fromSignUp ? 'Skip, I’ll use my password' : 'Not now',
                style: TextStyle(color: p.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final Color fg = enabled ? p.ink : p.faded;

    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? p.ink : p.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 168,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 38, color: fg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: Brand.wordmarkFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
