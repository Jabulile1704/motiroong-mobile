import 'dart:math' as math;
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

/// The MoTiroong "liquid glass" tab bar.
///
/// Rather than an edge-to-edge painted bar, this is the iOS floating
/// capsule: inset from all three edges so the page visibly runs
/// underneath it, filled with a translucent tint over a blurred and
/// saturated backdrop, rimmed with a specular highlight that is bright
/// along the top edge and almost gone along the bottom, and lifted off
/// the page by a soft shadow. A glass pill glides to the selected tab.
///
/// The hosting Scaffold needs `extendBody: true` for the blur to have
/// anything to work with.
class GlassNavBar extends StatefulWidget {
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
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> {
  /// Height of the capsule itself, excluding the margins around it.
  static const double _barHeight = 62;
  static const double _sideMargin = 16;
  static const double _maxPillWidth = 92;

  /// Keeps the first and last pill positions clear of the capsule's own
  /// rounded ends — without it the two radii visibly collide.
  static const double _horizontalInset = 6;

  /// The pill leads, the colors follow — one shared curve keeps them
  /// from arriving at different times.
  static const Duration _moveDuration = Duration(milliseconds: 340);
  static const Curve _moveCurve = Curves.easeOutCubic;

  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    final Color tint = isDark ? Brand.glassTintDark : Brand.glassTintLight;
    final Color rimTop = isDark
        ? Brand.glassRimTopDark
        : Brand.glassRimTopLight;
    final Color rimBottom = isDark
        ? Brand.glassRimBottomDark
        : Brand.glassRimBottomLight;
    final Color sheen = isDark ? Brand.glassSheenDark : Brand.glassSheenLight;
    final Color pill = isDark ? Brand.glassPillDark : Brand.glassPillLight;
    final Color pillRim = isDark
        ? Brand.glassPillRimDark
        : Brand.glassPillRimLight;
    final Color active = isDark ? Brand.offWhite : Brand.ink;
    final Color inactive = isDark ? Brand.placeholderGrey : Brand.mutedGrey;

    final BorderRadius radius = BorderRadius.circular(_barHeight / 2);

    // Clear the home indicator without floating halfway up the screen;
    // on devices with no inset the capsule still needs breathing room.
    final double bottomMargin = bottomInset > 0
        ? math.max(bottomInset - 12, 10)
        : 16;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _sideMargin,
        0,
        _sideMargin,
        bottomMargin,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: isDark
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ]
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F101014),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x0F101014),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            // Saturating as well as blurring is what separates glass from
            // frosted plastic: color bleeds through from the page below.
            filter: ImageFilter.compose(
              outer: const ColorFilter.matrix(_saturate),
              inner: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            ),
            child: CustomPaint(
              foregroundPainter: _RimPainter(
                radius: _barHeight / 2,
                top: rimTop,
                bottom: rimBottom,
              ),
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color.alphaBlend(sheen, tint),
                      tint,
                      tint,
                    ],
                    stops: const <double>[0, 0.55, 1],
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalInset,
                ),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double slot =
                        constraints.maxWidth / widget.items.length;
                    final double pillWidth = math.min(slot - 8, _maxPillWidth);

                    return Stack(
                      children: <Widget>[
                        AnimatedPositioned(
                          duration: _moveDuration,
                          curve: _moveCurve,
                          left:
                              slot * widget.currentIndex +
                              (slot - pillWidth) / 2,
                          top: 6,
                          bottom: 6,
                          width: pillWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: pill,
                              borderRadius: BorderRadius.circular(
                                (_barHeight - 12) / 2,
                              ),
                              border: Border.all(color: pillRim, width: 1),
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            for (int i = 0; i < widget.items.length; i++)
                              Expanded(
                                child: _GlassNavBarTab(
                                  item: widget.items[i],
                                  selected: i == widget.currentIndex,
                                  pressed: i == _pressedIndex,
                                  activeColor: active,
                                  inactiveColor: inactive,
                                  duration: _moveDuration,
                                  curve: _moveCurve,
                                  onTap: () => widget.onTap(i),
                                  onPressedChanged: (bool down) =>
                                      setState(() => _pressedIndex = down
                                          ? i
                                          : (_pressedIndex == i
                                                ? null
                                                : _pressedIndex)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tab: icon and label that fade between the active and
/// inactive colors, plus a small scale dip while the finger is down.
class _GlassNavBarTab extends StatelessWidget {
  const _GlassNavBarTab({
    required this.item,
    required this.selected,
    required this.pressed,
    required this.activeColor,
    required this.inactiveColor,
    required this.duration,
    required this.curve,
    required this.onTap,
    required this.onPressedChanged,
  });

  final GlassNavBarItem item;
  final bool selected;
  final bool pressed;
  final Color activeColor;
  final Color inactiveColor;
  final Duration duration;
  final Curve curve;
  final VoidCallback onTap;
  final ValueChanged<bool> onPressedChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (_) => onPressedChanged(true),
        onTapUp: (_) => onPressedChanged(false),
        onTapCancel: () => onPressedChanged(false),
        child: AnimatedScale(
          scale: pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
            duration: duration,
            curve: curve,
            builder: (BuildContext context, double t, Widget? child) {
              final Color color = Color.lerp(inactiveColor, activeColor, t)!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MotiIcon(
                    item.glyph,
                    size: 22,
                    color: color,
                    strokeWidth: 1.8 + 0.4 * t,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 10,
                      fontWeight: FontWeight.lerp(
                        FontWeight.w500,
                        FontWeight.w700,
                        t,
                      ),
                      letterSpacing: 0.1,
                      color: color,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Strokes the capsule's edge with a gradient so the rim is bright along
/// the top and fades out toward the bottom, the way a lit glass edge
/// catches light.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.radius,
    required this.top,
    required this.bottom,
  });

  final double radius;
  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke so the line lands inside the clip instead
    // of being shaved in half by it.
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, Color.lerp(top, bottom, 0.7)!, bottom],
        stops: const <double>[0, 0.45, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.radius != radius || old.top != top || old.bottom != bottom;
}

/// Saturation matrix (~1.7x) applied on top of the backdrop blur.
const List<double> _saturate = <double>[
  1.5509, -0.5005, -0.0504, 0, 0, //
  -0.1491, 1.1995, -0.0504, 0, 0, //
  -0.1491, -0.5005, 1.6496, 0, 0, //
  0, 0, 0, 1, 0, //
];
