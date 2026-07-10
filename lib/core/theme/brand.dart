import 'package:flutter/widgets.dart';

/// MoTiroong brand identity tokens.
///
/// Sources: design_handoff_motiroong_logo/README.md (the "Clock-in M"
/// mark, option 1c) and design_handoff_app_screens/README.md (the four
/// core screens). Strictly monochrome by design: no accent colors —
/// status/emphasis is conveyed via fill vs. outline vs. faded.
class Brand {
  Brand._();

  static const String wordmark = 'MoTiroong';
  static const String tagline = 'AT WORK';

  // Font families registered in pubspec.yaml.
  static const String wordmarkFont = 'SpaceGrotesk'; // headings/body
  static const String taglineFont = 'SpaceMono'; // labels/mono numerals

  // Transparent-background marks (1024×1024).
  static const String markWhite = 'assets/logo/mark_white_1024.png';
  static const String markBlack = 'assets/logo/mark_black_1024.png';

  // Core design tokens.
  static const Color ink = Color(0xFF101014); // dark bg / buttons / dark text
  static const Color offWhite = Color(0xFFF6F6F5); // screen bg / on-dark text
  static const Color mutedGrey = Color(0xFF6E6E76); // secondary/meta text
  static const Color lightGrey = Color(0xFFA7A7AE); // tertiary text, chevrons
  static const Color fieldGrey = Color(0xFFECECEE); // input fills, chips
  static const Color placeholderGrey = Color(0xFF8A8A90); // placeholders
  static const Color inactiveDot = Color(0xFF3A3A42); // splash loader
  static const Color darkHairline = Color(0xFF26262C); // borders on dark

  // Hairlines / translucent tokens (from the app-screens handoff).
  static const Color hairline = Color(0x14101014); // rgba(16,16,20,.08)
  static const Color rowHairline = Color(0x12101014); // rgba(16,16,20,.07)
  static const Color flaggedBorder = Color(0x59101014); // rgba(16,16,20,.35)
  // The handoff spec says rgba(16,16,20,0.58), but over the off-white
  // page that blurs to the same grey as the inactive icons — the design
  // overview renders the bar near-black, so we use 0.85 to match that
  // look and keep inactive items visible.
  static const Color glassBase = Color(0xD9101014);
  static const Color glassHairline = Color(0x24FFFFFF); // rgba(255,255,255,.14)

  /// Wordmark letter-spacing is -0.02em, i.e. relative to font size.
  static double wordmarkSpacing(double fontSize) => fontSize * -0.02;

  /// Tagline / eyebrow letter-spacing in em units.
  static double taglineSpacing(double fontSize) => fontSize * 0.42;
  static double emSpacing(double fontSize, double em) => fontSize * em;
}

/// Brightness-resolved surface/text roles for the app screens.
///
/// The handoff specifies the light appearance; dark mode maps the same
/// roles onto the brand's dark tokens so the screens stay legible when
/// the device is in dark mode.
class BrandPalette {
  const BrandPalette._({
    required this.background,
    required this.card,
    required this.ink,
    required this.muted,
    required this.faded,
    required this.field,
    required this.hairline,
    required this.rowHairline,
    required this.flaggedBorder,
    required this.onInk,
  });

  final Color background; // screen background
  final Color card; // card surface
  final Color ink; // primary text / filled elements
  final Color muted; // secondary text
  final Color faded; // tertiary/denied text
  final Color field; // input fills, chips, icon badges
  final Color hairline; // card borders
  final Color rowHairline; // separators inside cards
  final Color flaggedBorder; // "needs attention" outline
  final Color onInk; // text/icons on ink-filled elements

  static const BrandPalette light = BrandPalette._(
    background: Brand.offWhite,
    card: Color(0xFFFFFFFF),
    ink: Brand.ink,
    muted: Brand.mutedGrey,
    faded: Brand.lightGrey,
    field: Brand.fieldGrey,
    hairline: Brand.hairline,
    rowHairline: Brand.rowHairline,
    flaggedBorder: Brand.flaggedBorder,
    onInk: Brand.offWhite,
  );

  static const BrandPalette dark = BrandPalette._(
    background: Color(0xFF0B0B0D),
    card: Color(0xFF1A1A1E),
    ink: Brand.offWhite,
    muted: Brand.placeholderGrey,
    faded: Brand.mutedGrey,
    field: Brand.darkHairline,
    hairline: Color(0x1FFFFFFF),
    rowHairline: Color(0x14FFFFFF),
    flaggedBorder: Color(0x66F6F6F5),
    onInk: Brand.ink,
  );

  static BrandPalette of(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
      ? dark
      : light;

  /// Resolve from an explicit brightness (e.g. Theme.of(context).brightness).
  static BrandPalette forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;
}
