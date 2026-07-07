import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motirong/core/theme/app_theme.dart';
import 'package:motirong/features/attendance/presentation/screens/home_screen.dart';

void main() {
  // The AppScaffold's LiquidGlassBar depends on fragment shaders that are
  // not loaded in widget tests, so screens are pumped directly with the
  // app themes instead of through MotirongApp.
  Widget wrap(Widget child, {ThemeData? theme}) =>
      MaterialApp(theme: theme ?? AppTheme.light, home: child);

  testWidgets('Home screen shows status card and clock-in action',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const HomeScreen()));

    expect(find.text('Current status'), findsOneWidget);
    expect(find.text('Clock In'), findsOneWidget);
    expect(find.text('Clocked out'), findsOneWidget);
  });

  testWidgets('Home screen renders with the dark theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const HomeScreen(), theme: AppTheme.dark));

    expect(find.text('Clock In'), findsOneWidget);
  });

  test('themes are iOS-flavoured in both modes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.platform, TargetPlatform.iOS);
    expect(AppTheme.dark.platform, TargetPlatform.iOS);
  });
}
