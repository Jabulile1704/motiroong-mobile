import 'package:flutter/material.dart';

import '../theme/brand.dart';
import 'moti_icons.dart';

/// One row inside a Profile-style card: 32px icon badge + label +
/// trailing widget (chevron, value + chevron, or a switch).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.glyph,
    required this.label,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  final MotiGlyph glyph;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconBadge(glyph: glyph),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: Brand.wordmarkFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p.ink,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  fontFamily: Brand.wordmarkFont,
                  fontSize: 13,
                  color: p.muted,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (trailing != null)
              trailing!
            else if (showChevron)
              MotiIcon(MotiGlyph.chevron, size: 14, color: p.faded),
          ],
        ),
      ),
    );
  }
}

/// Small rounded icon container used across list rows.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.glyph,
    this.size = 32,
    this.iconSize = 16,
    this.radius = 8,
    this.border,
  });

  final MotiGlyph glyph;
  final double size;
  final double iconSize;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: MotiIcon(glyph, size: iconSize, color: p.ink, strokeWidth: 1.7),
    );
  }
}
