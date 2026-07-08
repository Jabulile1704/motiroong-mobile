import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motirong/core/services/location_service.dart';
import 'package:motirong/core/theme/app_theme.dart';
import 'package:motirong/core/utils/validators.dart';
import 'package:motirong/features/attendance/presentation/screens/home_screen.dart';
import 'package:motirong/features/auth/presentation/providers/auth_provider.dart';
import 'package:motirong/features/auth/presentation/screens/login_screen.dart';

void main() {
  // The AppScaffold's LiquidGlassBar depends on fragment shaders that are
  // not loaded in widget tests, so screens are pumped directly with the
  // app themes instead of through MotirongApp.
  Widget wrap(Widget child, {ThemeData? theme}) =>
      MaterialApp(theme: theme ?? AppTheme.light, home: child);

  testWidgets('Home screen shows status card and clock-in action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const HomeScreen()));

    expect(find.text('Current status'), findsOneWidget);
    expect(find.text('Clock In'), findsOneWidget);
    expect(find.text('Clocked out'), findsOneWidget);
  });

  testWidgets('Home screen renders with the dark theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const HomeScreen(), theme: AppTheme.dark));

    expect(find.text('Clock In'), findsOneWidget);
  });

  test('themes are iOS-flavoured in both modes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.platform, TargetPlatform.iOS);
    expect(AppTheme.dark.platform, TargetPlatform.iOS);
  });

  testWidgets('Login screen shows credentials form and geo-tag card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    // No geolocator plugin in tests, so the geo-tag capture cannot
    // complete and sign-in stays locked. (No pumpAndSettle: the pending
    // capture keeps its activity indicator animating.)
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('MoTiroong'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(
      find.text('Sign-in unlocks once your location is verified.'),
      findsOneWidget,
    );
  });

  test('validators accept emails and employee IDs, reject junk', () {
    expect(Validators.identifier('jabu@company.com'), isNull);
    expect(Validators.identifier('EMP-0042'), isNull);
    expect(Validators.identifier(''), isNotNull);
    expect(Validators.identifier('a b'), isNotNull);
    expect(Validators.password('1234'), isNull);
    expect(Validators.password(''), isNotNull);
  });

  test('auth provider signs in with a geo-tag and signs out', () async {
    final AuthProvider auth = AuthProvider();
    final LocationResult tag = LocationResult(
      latitude: -26.20227,
      longitude: 28.04363,
      accuracyMeters: 12,
      timestamp: DateTime.now(),
    );

    await auth.signIn(
      identifier: 'jabu@company.com',
      password: '1234',
      location: tag,
    );
    expect(auth.isSignedIn, isTrue);
    expect(auth.session?.fullName, 'Jabu');

    auth.signOut();
    expect(auth.isSignedIn, isFalse);

    await auth.signIn(
      identifier: 'jabu@company.com',
      password: 'wrong',
      location: tag,
    );
    expect(auth.isSignedIn, isFalse);
    expect(auth.errorMessage, isNotNull);
  });
}
