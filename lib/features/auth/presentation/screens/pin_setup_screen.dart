import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/widgets/screen_header.dart';
import '../widgets/pin_pad.dart';

/// Create-then-confirm PIN entry. Pops with the chosen PIN, or null if the
/// user backs out. Nothing is stored here: the caller sends the PIN to
/// `enrollDevice`, which keeps only an HMAC keyed with the device secret.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _first;
  String _entry = '';
  String? _error;

  /// Mirrors the backend's `isTrivialPin`, so the common refusals are caught
  /// before a round trip. The server still has the final say.
  static bool _isTrivial(String pin) {
    final List<int> d = pin.split('').map(int.parse).toList();
    if (d.every((x) => x == d.first)) return true;
    final List<int> steps = [
      for (int i = 1; i < d.length; i++) d[i] - d[i - 1],
    ];
    return steps.every((s) => s == 1) || steps.every((s) => s == -1);
  }

  void _onDigit(String digit) {
    if (_entry.length >= kPinLength) return;
    setState(() {
      _error = null;
      _entry += digit;
    });
    if (_entry.length == kPinLength) _complete();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  void _complete() {
    final String pin = _entry;
    if (_first == null) {
      if (_isTrivial(pin)) {
        setState(() {
          _entry = '';
          _error = 'That PIN is too easy to guess. Try another.';
        });
        return;
      }
      setState(() {
        _first = pin;
        _entry = '';
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _entry = '';
        _error = 'Those PINs didn’t match. Start again.';
      });
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final bool confirming = _first != null;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Back',
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(CupertinoIcons.back, color: p.ink),
              ),
              const SizedBox(height: 12),
              SectionEyebrow(confirming ? 'CONFIRM PIN' : 'CREATE PIN'),
              const SizedBox(height: 6),
              ScreenTitle(
                confirming ? 'Type it once more' : 'Choose a 6-digit PIN',
              ),
              const SizedBox(height: 8),
              Text(
                _error ??
                    (confirming
                        ? 'Just to be sure you’ve got it.'
                        : 'Avoid easy ones like 123456 or your birth year.'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: _error != null ? p.ink : p.muted,
                  fontWeight: _error != null ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(height: 44),
              PinDots(filled: _entry.length, error: _error != null),
              const Spacer(),
              PinPad(onDigit: _onDigit, onBackspace: _onBackspace),
            ],
          ),
        ),
      ),
    );
  }
}
