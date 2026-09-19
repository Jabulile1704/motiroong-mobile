import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';
import '../providers/auth_provider.dart';
import '../widgets/staff_card.dart';

/// Shown to a signed-in employee whose account is not `active` (design
/// direction C, "You're in the queue"). Pending, suspended and rejected all
/// land here; the copy changes with the status.
///
/// "Check again" re-reads the profile from the backend, which is the only
/// place approval status is trusted from.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checking = false;
  bool _sealed = false;
  QuickSignIn _method = QuickSignIn.biometric;

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    final bool sealed = await authProvider.hasBiometricEnrollment;
    final QuickSignIn method = await authProvider.enrolledMethod;
    if (!mounted) return;
    setState(() {
      _sealed = sealed;
      _method = method;
    });
  }

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    await authProvider.refreshProfile();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!authProvider.awaitingApproval) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Still waiting for approval.')),
      );
  }

  Future<void> _signOut() async {
    await authProvider.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final AuthResponse? session = authProvider.session;
    final EmployeeStatus status = session?.status ?? EmployeeStatus.pending;
    final bool pending = status == EmployeeStatus.pending;

    final String title = switch (status) {
      EmployeeStatus.pending => 'You’re in the queue',
      EmployeeStatus.suspended => 'Your account is suspended',
      EmployeeStatus.rejected => 'Your sign-up wasn’t approved',
      EmployeeStatus.active => 'You’re approved',
    };
    final String body = pending
        ? 'Your supervisor has to approve your account before you can clock in. '
              'Check back here once they have.'
        : (session?.statusReason ??
              'Please contact your supervisor or HR for details.');
    final String slotLabel = _sealed
        ? (_method == QuickSignIn.pin ? 'PIN' : 'QUICK SIGN-IN')
        : 'SIGN-IN';

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            StaffCard(
              name: session?.fullName ?? '',
              employeeId: session?.employeeId,
              department: session?.department,
              status: status.label.toUpperCase(),
              slotLabel: slotLabel,
              slotValue: _sealed ? 'SEALED TO THIS PHONE' : 'PASSWORD ONLY',
              sealed: _sealed,
              height: 220,
            ),
            const SizedBox(height: 28),
            ScreenTitle(title),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(fontSize: 15, height: 1.5, color: p.muted),
            ),
            if (pending) ...[
              const SizedBox(height: 24),
              BrandCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const _Step(done: true, label: 'Account created'),
                    _Step(
                      done: _sealed,
                      label: _sealed
                          ? 'Sealed to this phone'
                          : 'Quick sign-in not set up',
                    ),
                    const _Step(
                      done: false,
                      label: 'Supervisor approval',
                      last: true,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (pending)
              OutlinedButton(
                onPressed: _checking ? null : _checkAgain,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.flaggedBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _checking
                    ? const CupertinoActivityIndicator()
                    : const Text('Check again'),
              ),
            TextButton(
              onPressed: _signOut,
              child: Text('Sign out', style: TextStyle(color: p.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.done, required this.label, this.last = false});

  final bool done;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.rowHairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? p.ink : Colors.transparent,
              border: done ? null : Border.all(color: p.faded, width: 1.5),
            ),
            child: done
                ? Icon(CupertinoIcons.checkmark, size: 13, color: p.onInk)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: done ? p.ink : p.muted),
          ),
        ],
      ),
    );
  }
}
