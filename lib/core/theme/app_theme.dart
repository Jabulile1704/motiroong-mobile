import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// iOS-inspired light and dark themes.
///
/// Uses `platform: TargetPlatform.iOS` so every platform gets Cupertino
/// behaviour (bouncing scroll physics, back-swipe page transitions), plus
/// SF-style typography metrics and grouped-background surfaces.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color primary = AppColors.primary(brightness);
    final Color background = AppColors.background(brightness);
    final Color card = AppColors.card(brightness);
    final Color label = AppColors.label(brightness);
    final Color secondaryLabel = AppColors.secondaryLabel(brightness);
    final Color separator = AppColors.separator(brightness);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.success(brightness),
      error: AppColors.danger(brightness),
      surface: card,
      onSurface: label,
      onSurfaceVariant: secondaryLabel,
      outline: separator,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Brand body font per the app-screens handoff.
      fontFamily: 'SpaceGrotesk',
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      // iOS has no ink splashes.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: _textTheme(label, secondaryLabel),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: separator,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
          color: label,
        ),
        iconTheme: IconThemeData(color: primary),
        actionsIconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: separator,
        thickness: 0.5,
        space: 0.5,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: card,
        iconColor: primary,
        textColor: label,
        titleTextStyle: TextStyle(
          fontSize: 17,
          letterSpacing: -0.41,
          color: label,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 15,
          letterSpacing: -0.23,
          color: secondaryLabel,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 17, letterSpacing: -0.41),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fill(brightness),
        hintStyle: TextStyle(color: secondaryLabel, fontSize: 17),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success(brightness)
              : AppColors.fill(brightness),
        ),
      ),
      // Keeps embedded Cupertino widgets (pickers, switches, dialogs)
      // on the same tint and brightness as the Material theme.
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        barBackgroundColor: isDark
            ? const Color(0xE61C1C1E)
            : const Color(0xE6F2F2F7),
      ),
    );
  }

  /// SF Pro-like metrics mapped onto the Material text roles.
  static TextTheme _textTheme(Color label, Color secondaryLabel) {
    return TextTheme(
      // Large Title
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
        color: label,
      ),
      // Title 1
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.36,
        color: label,
      ),
      // Title 2
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
        color: label,
      ),
      // Title 3
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.38,
        color: label,
      ),
      // Headline
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
        color: label,
      ),
      // Subheadline
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.23,
        color: label,
      ),
      // Body
      bodyLarge: TextStyle(fontSize: 17, letterSpacing: -0.41, color: label),
      // Callout
      bodyMedium: TextStyle(fontSize: 16, letterSpacing: -0.31, color: label),
      // Footnote
      bodySmall: TextStyle(
        fontSize: 13,
        letterSpacing: -0.08,
        color: secondaryLabel,
      ),
      // Caption 1
      labelMedium: TextStyle(
        fontSize: 12,
        letterSpacing: 0,
        color: secondaryLabel,
      ),
      // Caption 2
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 0.07,
        color: secondaryLabel,
      ),
    );
  }
}
