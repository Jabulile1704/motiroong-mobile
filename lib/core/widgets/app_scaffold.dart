import 'package:flutter/material.dart';

import '../../features/attendance/presentation/screens/history_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/exceptions/presentation/screens/exception_request_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../theme/brand.dart';
import 'glass_nav_bar.dart';
import 'moti_icons.dart';

/// Main navigation shell.
///
/// Hosts the four tab screens behind the glass tab bar. `extendBody:
/// true` lets each page scroll underneath the translucent bar, and the
/// IndexedStack preserves each tab's scroll position.
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
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return Scaffold(
      backgroundColor: p.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          GlassNavBarItem(glyph: MotiGlyph.home, label: 'Home'),
          GlassNavBarItem(glyph: MotiGlyph.clock, label: 'History'),
          GlassNavBarItem(glyph: MotiGlyph.exception, label: 'Exceptions'),
          GlassNavBarItem(glyph: MotiGlyph.person, label: 'Profile'),
        ],
      ),
    );
  }
}
