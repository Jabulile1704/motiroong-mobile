import 'package:flutter/material.dart';
import 'package:motirong/core/widgets/splash_screen.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const MotirongApp());
}

/// Root of the application.
///
/// Registers the iOS-inspired light and dark themes and follows the
/// device appearance automatically via [ThemeMode.system].
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
      home: const LoginScreen(),
    );
  }
}
