import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/logo_lockup.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';
import '../widgets/staff_card.dart';

/// Sign-in.
///
/// On a phone sealed for quick sign-in (design direction C) the employee's
/// staff card is the sign-in button: tapping it runs Face ID / fingerprint,
/// or a PIN pad sits under it on a PIN phone. Either way the phone's device
/// secret goes to `signInWithDevice`, which mints the Firebase session.
///
/// Everyone else — and anyone who taps "Use email and password" — gets the
/// password form, where the location is captured first so the permission is
/// settled before the first clock-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _GeoStatus { fetching, captured, failed }

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocationService _locationService = const LocationService();

  bool _obscurePassword = true;

  // Quick sign-in: null while the device binding is being read.
  bool? _quick;
  bool _hasEnrollment = false;
  QuickSignIn _method = QuickSignIn.biometric;
  BiometricKind _kind = BiometricKind.none;
  String _enrolledName = '';
  String? _enrolledEmployeeId;
  String _pin = '';
  _GeoStatus _geoStatus = _GeoStatus.fetching;
  LocationResult? _location;
  String _geoError = '';

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    final bool enrolled = await authProvider.hasBiometricEnrollment;
    if (!enrolled) {
      if (!mounted) return;
      setState(() => _quick = false);
      _captureLocation();
      return;
    }
    final QuickSignIn method = await authProvider.enrolledMethod;
    final BiometricKind kind = await authProvider.biometricKind;
    final String? name = await authProvider.enrolledDisplayName;
    final String? employeeId = await authProvider.enrolledEmployeeId;
    if (!mounted) return;
    setState(() {
      _hasEnrollment = true;
      _quick = true;
      _method = method;
      _kind = kind;
      _enrolledName = name ?? '';
      _enrolledEmployeeId = employeeId;
    });
    // Offer Face ID / fingerprint straight away, as the OS apps do.
    if (method == QuickSignIn.biometric) _signInWithBiometrics();
  }

  void _usePassword() {
    authProvider.clearError();
    setState(() => _quick = false);
    if (_location == null) _captureLocation();
  }

  void _useQuick() {
    authProvider.clearError();
    setState(() {
      _quick = true;
      _pin = '';
    });
  }

  Future<void> _signInWithBiometrics() async {
    if (authProvider.isSigningIn) return;
    await authProvider.signInWithBiometrics();
    _afterSignIn();
  }

  void _onPinDigit(String digit) {
    if (_pin.length >= kPinLength || authProvider.isSigningIn) return;
    setState(() => _pin += digit);
    if (_pin.length == kPinLength) _signInWithPin();
  }

  void _onPinBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _signInWithPin() async {
    await authProvider.signInWithPin(_pin);
    if (!mounted) return;
    setState(() => _pin = '');
    _afterSignIn();
  }

  void _afterSignIn() {
    if (!mounted || !authProvider.isSignedIn) return;
    Navigator.of(context).pushReplacementNamed(authProvider.homeRoute);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _geoStatus = _GeoStatus.fetching;
      _geoError = '';
    });
    try {
      final LocationResult result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _location = result;
        _geoStatus = _GeoStatus.captured;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _geoStatus = _GeoStatus.failed;
        _geoError = e is LocationException
            ? e.message
            : 'Could not determine your location. Please try again.';
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final LocationResult? location = _location;
    if (location == null) {
      // No fix yet — try again rather than signing in untagged.
      await _captureLocation();
      if (_location == null) return;
    }
    // The fix is captured before sign-in so the location permission is
    // settled before the first clock-in, not sent with the credentials:
    // Firebase Auth owns identity, and the geo-tag is judged by clockIn.
    await authProvider.signIn(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );
    _afterSignIn();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: authProvider,
                builder: (context, _) {
                  if (_quick == null) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (_quick!) return _buildQuick(theme, brightness);
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 36),
                        _buildCredentialsCard(theme, brightness),
                        if (authProvider.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _buildAuthError(theme, brightness),
                        ],
                        const SizedBox(height: 16),
                        _buildGeoTagCard(theme, brightness),
                        const SizedBox(height: 24),
                        LoadingButton(
                          label: 'Sign In',
                          loading: authProvider.isSigningIn,
                          onPressed: _geoStatus == _GeoStatus.captured
                              ? _submit
                              : null,
                        ),
                        if (_geoStatus != _GeoStatus.captured) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Sign-in unlocks once your location is verified.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (_hasEnrollment)
                          TextButton(
                            onPressed: _useQuick,
                            child: Text('Use ${_quickTitle()} instead'),
                          ),
                        TextButton(
                          onPressed: authProvider.isSigningIn
                              ? null
                              : () =>
                                    Navigator.of(context).pushNamed('/signup'),
                          child: const Text('New here? Create an account'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Face ID", "Fingerprint" or "PIN" — whatever this phone was sealed with.
  String _quickTitle() => _method == QuickSignIn.pin
      ? 'PIN'
      : (_kind == BiometricKind.none ? defaultBiometricTitle() : _kind.title);

  /// Direction C, "Tap your card to sign in".
  Widget _buildQuick(ThemeData theme, Brightness brightness) {
    final BrandPalette p = BrandPalette.forBrightness(brightness);
    final bool busy = authProvider.isSigningIn;
    final bool pin = _method == QuickSignIn.pin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: LogoLockup(markSize: 30, wordmarkSize: 18, gap: 10),
        ),
        const SizedBox(height: 32),
        Text(
          pin ? 'ENTER YOUR PIN TO SIGN IN' : 'TAP YOUR CARD TO SIGN IN',
          style: TextStyle(
            fontFamily: Brand.taglineFont,
            fontSize: 11,
            letterSpacing: Brand.emSpacing(11, 0.14),
            color: p.muted,
          ),
        ),
        const SizedBox(height: 10),
        StaffCard(
          name: _enrolledName,
          employeeId: _enrolledEmployeeId,
          status: 'THIS PHONE',
          slotLabel: _quickTitle().toUpperCase(),
          slotValue: busy ? 'CHECKING…' : 'READY',
          sealed: true,
          height: 210,
          semanticLabel: 'Sign in as $_enrolledName with ${_quickTitle()}',
          onTap: pin || busy ? null : _signInWithBiometrics,
        ),
        if (authProvider.errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildAuthError(theme, brightness),
        ],
        const SizedBox(height: 24),
        if (pin) ...[
          PinDots(filled: _pin.length),
          const SizedBox(height: 24),
          if (busy)
            const Center(child: CupertinoActivityIndicator())
          else
            PinPad(onDigit: _onPinDigit, onBackspace: _onPinBackspace),
        ] else
          Center(
            child: busy
                ? const CupertinoActivityIndicator()
                : Column(
                    children: [
                      Icon(
                        _kind == BiometricKind.fingerprint
                            ? Icons.fingerprint
                            : CupertinoIcons.viewfinder,
                        size: 40,
                        color: p.muted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_quickTitle()} will check it’s you',
                        style: TextStyle(fontSize: 14, color: p.muted),
                      ),
                    ],
                  ),
          ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: busy ? null : _usePassword,
          child: const Text('Sign in with email and password'),
        ),
        TextButton(
          onPressed: busy ? null : _usePassword,
          child: Text(
            'Not $_enrolledName? Switch account',
            style: TextStyle(color: p.faded),
          ),
        ),
      ],
    );
  }

  /// Brand header per the logo handoff: mark + wordmark lockup, then the
  /// "Clock in" heading and supporting subtext.
  Widget _buildHeader(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        const LogoLockup(markSize: 38, wordmarkSize: 22, gap: 12),
        const SizedBox(height: 32),
        Text(
          'Clock in',
          style: TextStyle(
            fontFamily: Brand.wordmarkFont,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: Brand.wordmarkSpacing(20),
            color: isDark ? Brand.offWhite : Brand.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to start your shift and manage your attendance',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Brand.lightGrey : Brand.mutedGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsCard(ThemeData theme, Brightness brightness) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _identifierController,
              validator: Validators.identifier,
              enabled: !authProvider.isSigningIn,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Email or employee ID',
                prefixIcon: Icon(CupertinoIcons.person, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              validator: Validators.password,
              enabled: !authProvider.isSigningIn,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthError(ThemeData theme, Brightness brightness) {
    final Color danger = AppColors.danger(brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            size: 18,
            color: danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              authProvider.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(color: danger),
            ),
          ),
        ],
      ),
    );
  }

  /// The geo-tag card: shows the live state of the location capture that
  /// will be attached to this sign-in.
  Widget _buildGeoTagCard(ThemeData theme, Brightness brightness) {
    final Color success = AppColors.success(brightness);
    final Color warning = AppColors.warning(brightness);

    final (
      Widget leading,
      String title,
      String subtitle,
    ) = switch (_geoStatus) {
      _GeoStatus.fetching => (
        const CupertinoActivityIndicator(),
        'Verifying your location…',
        'Your sign-in will be geo-tagged for attendance records.',
      ),
      _GeoStatus.captured => (
        Icon(CupertinoIcons.checkmark_seal_fill, size: 26, color: success),
        'Location verified',
        '${_location!.coordinatesLabel} · ±${_location!.accuracyMeters.round()} m',
      ),
      _GeoStatus.failed => (
        Icon(CupertinoIcons.location_slash_fill, size: 26, color: warning),
        'Location unavailable',
        _geoError,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(width: 32, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (_geoStatus == _GeoStatus.failed)
              TextButton(
                onPressed: _captureLocation,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
