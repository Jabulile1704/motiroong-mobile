import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';

import '../../features/attendance/presentation/screens/history_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/exceptions/presentation/screens/exception_request_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../theme/app_colors.dart';

/// Main navigation shell.
///
/// Hosts the four tab screens behind a floating iOS-style liquid-glass
/// bottom bar. `extendBody: true` lets each page scroll underneath the
/// translucent bar, which is what sells the glass effect.
class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    HistoryScreen(),
    ExceptionRequestScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: LiquidGlassBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          LiquidGlassBarItem(
              iconData: CupertinoIcons.house_fill, label: 'Home'),
          LiquidGlassBarItem(
              iconData: CupertinoIcons.clock_fill, label: 'History'),
          LiquidGlassBarItem(
              iconData: CupertinoIcons.doc_text_fill, label: 'Requests'),
          LiquidGlassBarItem(
              iconData: CupertinoIcons.person_fill, label: 'Profile'),
        ],
        style: LiquidGlassBarStyle(
          activeColor: AppColors.primary(brightness),
          inactiveColor: AppColors.secondaryLabel(brightness),
          borderRadius: 32,
          height: 57,
          iconSize: 24,
          selectedIconScale: 1.15,
          animationDuration: const Duration(milliseconds: 250),
          animationCurve: Curves.easeOutQuad,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.07,
          ),
        ),
      ),
    );
  }
}
