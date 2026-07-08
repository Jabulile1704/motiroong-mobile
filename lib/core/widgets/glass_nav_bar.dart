import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Item model for [GlassNavBar], mirroring LiquidGlassBarItem.
class GlassNavBarItem {
  const GlassNavBarItem({required this.iconData, required this.label});

  final IconData iconData;
  final String label;
}

/// Web-safe frosted-glass bottom navigation bar.
///
/// The liquid_glass_bar package relies on Impeller fragment shaders that
/// cannot compile for Flutter web, so this bar recreates the floating
/// iOS glass look with a plain [BackdropFilter] blur, which works on
/// every platform including Chrome.
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
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color active = AppColors.primary(brightness);
    final Color inactive = AppColors.secondaryLabel(brightness);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                  .withValues(alpha: isDark ? 0.55 : 0.6),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.1,
                ),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: i == currentIndex ? 1.15 : 1,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutQuad,
                            child: Icon(
                              items[i].iconData,
                              size: 24,
                              color: i == currentIndex ? active : inactive,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.07,
                              color: i == currentIndex ? active : inactive,
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
      ),
    );
  }
}
