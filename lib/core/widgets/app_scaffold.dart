import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../features/attendance/presentation/screens/history_screen.dart';
import '../../features/attendance/presentation/screens/home_screen.dart';
import '../../features/exceptions/presentation/screens/exception_request_screen.dart';
import '../../features/profile/profile_screen.dart';
import 'glass_nav_bar.dart';

/// Main navigation shell.
///
/// Hosts the four tab screens behind a floating iOS-style glass bottom
/// bar. `extendBody: true` lets each page scroll underneath the
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
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          GlassNavBarItem(iconData: CupertinoIcons.house_fill, label: 'Home'),
          GlassNavBarItem(
            iconData: CupertinoIcons.clock_fill,
            label: 'History',
          ),
          GlassNavBarItem(
            iconData: CupertinoIcons.doc_text_fill,
            label: 'Requests',
          ),
          GlassNavBarItem(
            iconData: CupertinoIcons.person_fill,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
