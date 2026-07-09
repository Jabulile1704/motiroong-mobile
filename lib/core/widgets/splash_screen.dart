import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Branded in-app splash, per the handoff splash spec: ink background,
/// white mark, wordmark, "AT WORK" tagline, and a 3-dot loader near the
/// bottom. Shown briefly at startup while the app initializes; it picks
/// up seamlessly from the native splash (same ink bg + white mark).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _activeDot = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      setState(() => _activeDot = (_activeDot + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
