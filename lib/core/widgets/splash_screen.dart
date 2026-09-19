import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/brand.dart';

/// Branded in-app splash, per the handoff splash spec: ink background,
/// white mark, wordmark, "AT WORK" tagline, and a 3-dot loader near the
/// bottom. Shown at startup while the app initializes; it picks up
/// seamlessly from the native splash (same ink bg + white mark) and then
/// navigates on to the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.navigateOnDone = true});

  /// Set false to keep the splash on screen (previews, tests).
  final bool navigateOnDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _activeDot = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      setState(() => _activeDot = (_activeDot + 1) % 3);
    });
    if (widget.navigateOnDone) {
      unawaited(_restoreAndRoute());
    }
  }

  /// Restores a Firebase session, if there is one, then routes.
  ///
  /// Firebase persists the session across restarts, so a returning employee
  /// should land on the home screen without seeing the login form. The splash
  /// is held for its full animation either way — the profile call is usually
  /// faster than that, and a splash that flickers past looks broken.
  Future<void> _restoreAndRoute() async {
    final Future<void> minimumHold = Future<void>.delayed(
      const Duration(milliseconds: 2200),
    );

    await authProvider.restore();
    // A phone nobody has registered on opens on sign-up; after that, sign-in.
    final bool registered = await authProvider.isRegisteredDevice;
    await minimumHold;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      authProvider.isSignedIn
          ? authProvider.homeRoute
          : (registered ? '/login' : '/signup'),
    );
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.ink,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    Brand.markWhite,
                    width: 96,
                    height: 96,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    Brand.wordmark,
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      letterSpacing: Brand.wordmarkSpacing(27),
                      color: Brand.offWhite,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    Brand.tagline,
                    style: TextStyle(
                      fontFamily: Brand.taglineFont,
                      fontSize: 11,
                      letterSpacing: Brand.taglineSpacing(11),
                      color: Brand.mutedGrey,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _activeDot
                            ? Brand.offWhite
                            : Brand.inactiveDot,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
