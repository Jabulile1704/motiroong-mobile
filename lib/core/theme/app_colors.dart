import 'package:flutter/widgets.dart';

/// iOS system palette (Apple Human Interface Guidelines colors),
/// with a light and a dark variant for every role.
class AppColors {
  AppColors._();

  // Tint / brand — iOS systemBlue.
  static const Color primaryLight = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0A84FF);

  // Semantic colors.
  static const Color successLight = Color(0xFF34C759); // systemGreen
  static const Color successDark = Color(0xFF30D158);
  static const Color dangerLight = Color(0xFFFF3B30); // systemRed
  static const Color dangerDark = Color(0xFFFF453A);
  static const Color warningLight = Color(0xFFFF9500); // systemOrange
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color infoLight = Color(0xFF5856D6); // systemIndigo
  static const Color infoDark = Color(0xFF5E5CE6);
  static const Color tealLight = Color(0xFF30B0C7); // systemTeal
  static const Color tealDark = Color(0xFF40C8E0);

  // Backgrounds — grouped style, like the iOS Settings app.
  static const Color backgroundLight =
      Color(0xFFF2F2F7); // systemGroupedBackground
  static const Color backgroundDark = Color(0xFF000000);
  static const Color cardLight =
      Color(0xFFFFFFFF); // secondarySystemGroupedBackground
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color elevatedCardDark = Color(0xFF2C2C2E);

  // Labels.
  static const Color labelLight = Color(0xFF000000);
  static const Color labelDark = Color(0xFFFFFFFF);
  static const Color secondaryLabelLight = Color(0x993C3C43); // 60% opacity
  static const Color secondaryLabelDark = Color(0x99EBEBF5);
  static const Color tertiaryLabelLight = Color(0x4D3C3C43); // 30% opacity
  static const Color tertiaryLabelDark = Color(0x4DEBEBF5);

  // Separators (hairlines between list rows).
  static const Color separatorLight = Color(0x4D3C3C43);
  static const Color separatorDark = Color(0x59545458);

  // Fills — text fields, inactive controls.
  static const Color fillLight = Color(0x1F787880); // 12% opacity
  static const Color fillDark = Color(0x3D787880); // 24% opacity

  // Convenience resolvers so widgets don't need brightness checks everywhere.
  static Color primary(Brightness b) =>
      b == Brightness.dark ? primaryDark : primaryLight;
  static Color success(Brightness b) =>
      b == Brightness.dark ? successDark : successLight;
  static Color danger(Brightness b) =>
      b == Brightness.dark ? dangerDark : dangerLight;
  static Color warning(Brightness b) =>
      b == Brightness.dark ? warningDark : warningLight;
  static Color card(Brightness b) =>
      b == Brightness.dark ? cardDark : cardLight;
  static Color background(Brightness b) =>
      b == Brightness.dark ? backgroundDark : backgroundLight;
  static Color label(Brightness b) =>
      b == Brightness.dark ? labelDark : labelLight;
  static Color secondaryLabel(Brightness b) =>
      b == Brightness.dark ? secondaryLabelDark : secondaryLabelLight;
  static Color separator(Brightness b) =>
      b == Brightness.dark ? separatorDark : separatorLight;
  static Color fill(Brightness b) =>
      b == Brightness.dark ? fillDark : fillLight;
}
