import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Full-width iOS-style filled button that swaps its label for a
/// [CupertinoActivityIndicator] while an async action is in flight.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? scheme.primary,
        disabledBackgroundColor:
            (color ?? scheme.primary).withValues(alpha: 0.5),
      ),
      child: loading
          ? const CupertinoActivityIndicator(color: Colors.white)
          : Text(label),
    );
  }
}
