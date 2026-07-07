import 'package:flutter/material.dart';

/// Home screen — the primary clock-in/clock-out screen for employees.
///
/// This is UI-only: local state simulates the clocked-in/out toggle so the
/// screen is fully navigable and previewable on its own. Wire the TODOs
/// below to `core/services/location_service.dart`,
/// `core/services/biometric_service.dart`, and
/// `features/attendance/presentation/providers/attendance_provider.dart`
/// once those are ready.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---- Placeholder state (replace with provider/bloc-backed state) ----
  bool _isClockedIn = true;
  final String _employeeName = 'Jabulile Mashibini';
  final String _siteName = 'Main office site';
  final String _lastActionTime = '07:58';
  bool _isSubmitting = false;

  Future<void> _handleClockAction() async {
    setState(() => _isSubmitting = true);

    // TODO: replace this delay with the real flow:
    // 1. locationService.getCurrentPosition()
    // 2. biometricService.authenticate()
    // 3. attendanceRepository.clockIn() / clockOut()
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() {
      _isClockedIn = !_isClockedIn;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(theme),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildLocationPreview(),
              const Spacer(),
              _buildClockButton(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _employeeName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final color = _isClockedIn ? Colors.green : Colors.grey;
    final backgroundColor = _isClockedIn
        ? Colors.green.shade50
        : Colors.grey.shade100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isClockedIn ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: color.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                _isClockedIn ? 'Clocked in' : 'Not clocked in',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_lastActionTime · $_siteName',
            style: TextStyle(fontSize: 13, color: color.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPreview() {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // TODO: replace with an embedded map widget (e.g. google_maps_flutter)
          // centered on the employee's current position and the site geofence.
          Icon(Icons.location_on, size: 28, color: Colors.blueGrey.shade400),
          const Positioned(
            bottom: 10,
            child: Text(
              'Within site radius',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockButton() {
    final isClockingOut = _isClockedIn;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleClockAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: isClockingOut
              ? Colors.red.shade600
              : Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.fingerprint),
        label: Text(
          _isSubmitting
              ? 'Verifying…'
              : (isClockingOut ? 'Clock out' : 'Clock in'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey.shade500,
      showUnselectedLabels: true,
      // TODO: wire to app_router.dart navigation instead of a static index.
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.error_outline),
          label: 'Exceptions',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
