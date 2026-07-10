import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/widgets/moti_icons.dart';

/// The primary clock action, per the app-screens handoff: a 132px ink
/// circle with a filled square (clock out) or play triangle (clock in)
/// and a label, floating on a soft shadow. Press scales it down subtly;
/// a spinner replaces the content while the action is processing.
class ClockButton extends StatefulWidget {
  const ClockButton({
    super.key,
    required this.clockedIn,
    required this.onPressed,
    this.busy = false,
  });

  final bool clockedIn;
  final VoidCallback onPressed;
  final bool busy;

  @override
  State<ClockButton> createState() => _ClockButtonState();
}

class _ClockButtonState extends State<ClockButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return GestureDetector(
      onTapDown: widget.busy ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: widget.busy
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: p.ink,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x47101014), // rgba(16,16,20,0.28)
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: widget.busy
                ? CupertinoActivityIndicator(radius: 13, color: p.onInk)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MotiIcon(
                        widget.clockedIn ? MotiGlyph.stop : MotiGlyph.play,
                        size: 22,
                        color: p.onInk,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.clockedIn ? 'Clock Out' : 'Clock In',
                        style: TextStyle(
                          fontFamily: Brand.wordmarkFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.onInk,
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
