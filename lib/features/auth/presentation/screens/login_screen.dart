import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/logo_lockup.dart';
import '../providers/auth_provider.dart';

/// iOS-style login screen with geo-tagged sign-in.
///
/// The device's location is captured while the user types; the fix is
/// attached to the login request so the server knows where the session
/// started. Sign-in is blocked until a location fix is available.
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
  _GeoStatus _geoStatus = _GeoStatus.fetching;
  LocationResult? _location;
  String _geoError = '';

  @override
  void initState() {
    super.initState();
    _captureLocation();
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
    await authProvider.signIn(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
      location: _location!,
    );
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
