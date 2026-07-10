import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Shared screen chrome per the app-screens handoff: 22px mark +
/// wordmark on the left, optional 36px circular avatar (initials) on the
/// right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, this.initials});

  final String? initials;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Image.asset(
          isDark ? Brand.markWhite : Brand.markBlack,
          width: 22,
          height: 22,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: 8),
        Text(
          Brand.wordmark,
          style: TextStyle(
            fontFamily: Brand.wordmarkFont,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: Brand.emSpacing(15, -0.01),
            color: p.ink,
          ),
        ),
        const Spacer(),
        if (initials != null)
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
            child: Text(
              initials!,
              style: TextStyle(
                fontFamily: Brand.wordmarkFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.onInk,
              ),
            ),
          ),
      ],
    );
  }
}

/// Space Mono uppercase eyebrow above a screen title, e.g. "ACTIVITY LOG".
class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: Brand.taglineFont,
        fontSize: 11,
        letterSpacing: Brand.emSpacing(11, 0.18),
        color: p.muted,
      ),
    );
  }
}

/// Screen title, 24px Space Grotesk 600.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Text(
      text,
      style: TextStyle(
        fontFamily: Brand.wordmarkFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: Brand.emSpacing(24, -0.01),
        color: p.ink,
      ),
    );
  }
}

/// Small Space Mono uppercase label above a card group, e.g. "THIS WEEK".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: Brand.taglineFont,
        fontSize: 10,
        letterSpacing: Brand.emSpacing(10, 0.16),
        color: p.muted,
      ),
    );
  }
}

/// Standard content card: white surface, hairline border, 20px radius.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? p.hairline,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}
