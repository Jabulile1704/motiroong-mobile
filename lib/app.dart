import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_scaffold.dart';
import 'core/widgets/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/pending_approval_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';

/// Root of the application.
///
/// Registers the iOS-inspired light and dark themes, follows the device
/// appearance via [ThemeMode.system], and defines the navigation flow:
///
///   '/'       SplashScreen — /signup on a phone nobody has registered on,
///             otherwise /login (or straight in with a live session)
///   '/login'  LoginScreen  — card (Face ID / fingerprint / PIN) or password
///   '/signup' SignUpScreen — details, then seal to this phone
///   '/pending' PendingApprovalScreen — signed in, account not yet active
///   '/home'   AppScaffold  — the main app; signing out returns to /login
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
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/pending': (_) => const PendingApprovalScreen(),
        '/home': (_) => const AppScaffold(),
      },
    );
  }
}
