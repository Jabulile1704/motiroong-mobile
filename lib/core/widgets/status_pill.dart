import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Status language per the handoff: emphasis via fill vs. outline vs.
/// faded, never hue.
enum StatusPillStyle {
  /// Neutral chip: field-grey fill ("On time", "7h 58m").
  filled,

  /// Needs attention / pending: transparent fill, ink border ("Late").
  outlined,

  /// Strong positive: solid ink fill, light text ("Approved").
  inverse,

  /// De-emphasized: field-grey fill, faded text ("Denied").
  faded,
}

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.style = StatusPillStyle.filled,
  });

  final String label;
  final StatusPillStyle style;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    final (Color bg, Color fg, Border? border) = switch (style) {
      StatusPillStyle.filled => (p.field, p.ink, null),
      StatusPillStyle.outlined => (
        Colors.transparent,
        p.ink,
        Border.all(color: p.ink, width: 1),
      ),
      StatusPillStyle.inverse => (p.ink, p.onInk, null),
      StatusPillStyle.faded => (p.field, p.faded, null),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: border == null ? 5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Brand.taglineFont,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}
