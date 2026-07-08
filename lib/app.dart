import 'dart:async';

import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_scaffold.dart';
import 'core/widgets/splash_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';

/// Root of the application.
///
/// Registers the iOS-inspired light and dark themes, follows the device
/// appearance via [ThemeMode.system], and routes between the branded
/// splash, the login screen and the main app.
class MotirongApp extends StatelessWidget {
  const MotirongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _StartupGate(),
    );
  }
}

/// Shows the branded [SplashScreen] briefly at launch (continuing from
/// the native splash), then hands over to login / the main app.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    // Placeholder for real startup work (restore session, warm caches).
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _booting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 3500),
      child: _booting
          ? const SplashScreen()
          : ListenableBuilder(
              listenable: authProvider,
              builder: (context, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 3500),
                  child: authProvider.isSignedIn
                      ? const AppScaffold()
                      : const LoginScreen(),
                );
              },
            ),
    );
  }
}
