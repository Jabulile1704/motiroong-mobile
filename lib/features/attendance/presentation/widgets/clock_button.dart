import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Big circular clock in/out button — green gradient when the user can
/// clock in, red when they can clock out, with an iOS-style press
/// scale-down and a spinner while the action is processing.
class ClockButton extends StatefulWidget {
  const ClockButton({
    super.key,
    required this.clockedIn,
    required this.onPressed,
    this.busy = false,
    this.size = 190,
  });

  final bool clockedIn;
  final VoidCallback onPressed;
  final bool busy;
  final double size;

  @override
  State<ClockButton> createState() => _ClockButtonState();
}

class _ClockButtonState extends State<ClockButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color color = widget.clockedIn
        ? AppColors.danger(brightness)
        : AppColors.success(brightness);

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
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.85), color],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: widget.busy
                ? const CupertinoActivityIndicator(
                    radius: 16,
                    color: Colors.white,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.clockedIn
                            ? CupertinoIcons.stop_fill
                            : CupertinoIcons.play_fill,
                        size: 44,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.clockedIn ? 'Clock Out' : 'Clock In',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.41,
                          color: Colors.white,
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
