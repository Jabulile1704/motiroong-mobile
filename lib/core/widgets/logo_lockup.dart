import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// The MoTiroong logo lockup: mark on the left, wordmark to the right,
/// vertically centered — per the brand handoff. Theme-aware: black mark
/// and ink text on light surfaces, white mark and off-white text on dark.
class LogoLockup extends StatelessWidget {
  const LogoLockup({
    super.key,
    this.markSize = 38,
    this.wordmarkSize = 22,
    this.gap = 12,
  });

  final double markSize;
  final double wordmarkSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          isDark ? Brand.markWhite : Brand.markBlack,
          width: markSize,
          height: markSize,
          filterQuality: FilterQuality.medium,
        ),
        SizedBox(width: gap),
        Text(
          Brand.wordmark,
          style: TextStyle(
            fontFamily: Brand.wordmarkFont,
            fontSize: wordmarkSize,
            fontWeight: FontWeight.w600,
            letterSpacing: Brand.wordmarkSpacing(wordmarkSize),
            color: isDark ? Brand.offWhite : Brand.ink,
          ),
        ),
      ],
    );
  }
}
