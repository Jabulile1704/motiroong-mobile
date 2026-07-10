import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/brand.dart';
import 'moti_icons.dart';

/// Item model for [GlassNavBar].
class GlassNavBarItem {
  const GlassNavBarItem({required this.glyph, required this.label});

  final MotiGlyph glyph;
  final String label;
}

/// The MoTiroong "liquid glass" tab bar, per the app-screens handoff:
/// pinned to the bottom edge, `rgba(16,16,20,0.58)` over a 20px blur,
/// a 1px top hairline, 22px custom line icons + 10px labels. Active
/// item is off-white, inactive is muted grey. Content scrolls behind it
/// (`extendBody: true` on the hosting Scaffold).
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Brand.glassBase,
            border: Border(
              top: BorderSide(color: Brand.glassHairline, width: 1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            8,
            14,
            8,
            bottomInset > 14 ? bottomInset : 28,
          ),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MotiIcon(
                          items[i].glyph,
                          size: 22,
                          color: i == currentIndex
                              ? Brand.offWhite
                              : Brand.mutedGrey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontFamily: Brand.wordmarkFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: i == currentIndex
                                ? Brand.offWhite
                                : Brand.mutedGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
