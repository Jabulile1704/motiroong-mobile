import 'package:flutter/material.dart';

import 'features/attendance/presentation/screens/home_screen.dart';

/// Root widget — MaterialApp, theme, and routing live here.
class MoTirong extends StatelessWidget {
  const MoTirong({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoTirong',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),

      // TODO: once routing/app_router.dart exists (go_router), replace
      // `home:` with:
      //   routerConfig: appRouter,
      // and remove the MaterialApp `home` property entirely.
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      // Green seed matches the "verified/success" status color used
      // throughout the attendance screens (status cards, clock-in button).
      colorSchemeSeed: const Color(0xFF2E7D32),
      scaffoldBackgroundColor: const Color(0xFFF5F5F3),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
