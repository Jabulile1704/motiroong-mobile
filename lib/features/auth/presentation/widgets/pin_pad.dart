import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/brand.dart';

/// Length of a sign-in PIN. Must match `requirePin` in the backend.
const int kPinLength = 6;

/// Six dots showing how many digits have been entered.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filled, this.error = false});

  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Semantics(
      label: '$filled of $kPinLength digits entered',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < kPinLength; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? p.ink : Colors.transparent,
                border: Border.all(
                  color: error
                      ? p.flaggedBorder
                      : (i < filled ? p.ink : p.faded),
                  width: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Numeric keypad. Reports each digit and backspace; the owner keeps the
/// entered value, so the same pad serves "create", "confirm" and "sign in".
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    const List<String> keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      'del',
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        for (final String k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else if (k == 'del')
            _Key(
              enabled: enabled,
              background: Colors.transparent,
              semanticLabel: 'Delete',
              onTap: onBackspace,
              child: Icon(CupertinoIcons.delete_left, color: p.ink, size: 26),
            )
          else
            _Key(
              enabled: enabled,
              background: p.card,
              semanticLabel: k,
              onTap: () => onDigit(k),
              child: Text(
                k,
                style: TextStyle(
                  fontFamily: Brand.wordmarkFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: p.ink,
                ),
              ),
            ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.child,
    required this.onTap,
    required this.background,
    required this.semanticLabel,
    required this.enabled,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color background;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Center(child: child),
        ),
      ),
    );
  }
}
