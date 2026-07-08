import 'package:flutter/widgets.dart';

/// MoTiroong brand identity tokens.
///
/// Source: design_handoff_motiroong_logo/README.md — the "Clock-in M"
/// mark (option 1c). Strictly monochrome by design: no accent colors.
class Brand {
  Brand._();

  static const String wordmark = 'MoTiroong';
  static const String tagline = 'AT WORK';

  // Font families registered in pubspec.yaml.
  static const String wordmarkFont = 'SpaceGrotesk'; // 600, -0.02em
  static const String taglineFont = 'SpaceMono'; // 400, +0.42em

  // Transparent-background marks (1024×1024).
  static const String markWhite = 'assets/logo/mark_white_1024.png';
  static const String markBlack = 'assets/logo/mark_black_1024.png';

  // Design tokens.
  static const Color ink = Color(0xFF101014); // dark bg / dark mark
  static const Color offWhite = Color(0xFFF6F6F5); // light tile / on-dark text
  static const Color mutedGrey = Color(0xFF6E6E76); // taglines, secondary
  static const Color lightGrey = Color(0xFFA7A7AE); // body text on dark
  static const Color inactiveDot = Color(0xFF3A3A42); // splash loader

  /// Wordmark letter-spacing is -0.02em, i.e. relative to font size.
  static double wordmarkSpacing(double fontSize) => fontSize * -0.02;

  /// Tagline letter-spacing is +0.42em.
  static double taglineSpacing(double fontSize) => fontSize * 0.42;
}
