import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_scaffold.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';

/// Root of the application.
///
/// Registers the iOS-inspired light and dark themes, follows the device
/// appearance via [ThemeMode.system], and switches between the login
/// screen and the main app based on the auth state.
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
      home: ListenableBuilder(
        listenable: authProvider,
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: authProvider.isSignedIn
                ? const AppScaffold()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
