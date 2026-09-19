import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';

/// The ink staff card at the heart of sign-up and sign-in (design direction
/// C): it fills in live as the employee types, is "sealed" to the phone when
/// they set up Face ID, fingerprint or a PIN, and is the button they tap to
/// sign in afterwards.
///
/// Always ink-on-off-white, in light and dark mode alike — it is an object,
/// like a physical ID badge, not a surface that follows the theme.
class StaffCard extends StatelessWidget {
  const StaffCard({
    super.key,
    required this.name,
    this.employeeId,
    this.department,
    this.status = 'PENDING APPROVAL',
    this.slotLabel = 'SIGN-IN',
    this.slotValue = 'NOT SET',
    this.sealed = false,
    this.height = 196,
    this.onTap,
    this.semanticLabel,
  });

  final String name;
  final String? employeeId;
  final String? department;
  final String status;

  /// The bottom row: which quick sign-in is set up, e.g. `FACE ID` / `READY`.
  final String slotLabel;
  final String slotValue;

  /// True once a device binding exists — fills the dashed seal.
  final bool sealed;
  final double height;
  final VoidCallback? onTap;
  final String? semanticLabel;

  static const TextStyle _mono = TextStyle(
    fontFamily: Brand.taglineFont,
    color: Brand.offWhite,
  );

  @override
  Widget build(BuildContext context) {
    final String meta = [
      if (employeeId != null && employeeId!.isNotEmpty) employeeId!,
      if (department != null && department!.isNotEmpty) department!,
    ].join(' · ').toUpperCase();

    final Widget card = Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(Brand.markWhite, width: 22, height: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MOTIROONG · STAFF',
                  style: _mono.copyWith(
                    fontSize: 10,
                    letterSpacing: Brand.emSpacing(10, 0.16),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x4DF6F6F5)),
                ),
                child: Text(
                  status,
                  style: _mono.copyWith(
                    fontSize: 9,
                    letterSpacing: Brand.emSpacing(9, 0.12),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  name.trim().isEmpty ? 'Your name' : name.trim(),
                  key: ValueKey<bool>(name.trim().isEmpty),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: Brand.wordmarkSpacing(24),
                    color: name.trim().isEmpty
                        ? Brand.mutedGrey
                        : Brand.offWhite,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta.isEmpty ? 'EMPLOYEE ID · DEPARTMENT' : meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _mono.copyWith(fontSize: 12, color: Brand.lightGrey),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x24F6F6F5))),
            ),
            child: Row(
              children: [
                _Seal(sealed: sealed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$slotLabel ',
                          style: const TextStyle(color: Brand.lightGrey),
                        ),
                        TextSpan(text: slotValue),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono.copyWith(
                      fontSize: 11,
                      letterSpacing: Brand.emSpacing(11, 0.08),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: card,
        ),
      ),
    );
  }
}

class _Seal extends StatelessWidget {
  const _Seal({required this.sealed});

  final bool sealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: sealed ? Brand.offWhite : Colors.transparent,
        border: sealed ? null : Border.all(color: Brand.lightGrey, width: 1.5),
      ),
      child: sealed
          ? const Icon(CupertinoIcons.checkmark, size: 13, color: Brand.ink)
          : null,
    );
  }
}
