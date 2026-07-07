import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/attendance_record.dart';
import '../widgets/clock_button.dart';
import '../widgets/status_card.dart';

/// Home tab: iOS large-title header, current status card and the main
/// clock in/out action.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  ClockStatus _status = ClockStatus.clockedOut;
  DateTime? _clockInTime;

  Future<void> _toggleClock() async {
    setState(() => _busy = true);
    // Placeholder for the real attendance repository call
    // (location check + API request + offline queue).
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (_status == ClockStatus.clockedIn) {
        _status = ClockStatus.clockedOut;
        _clockInTime = null;
      } else {
        _status = ClockStatus.clockedIn;
        _clockInTime = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final bool clockedIn = _status == ClockStatus.clockedIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              20, 12, 20, AppConstants.bottomBarClearance),
          children: [
            // Large-title header, iOS style.
            Text(
              DateFormatter.fullDate(now).toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${DateFormatter.greeting(now)} 👋',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),

            StatusCard(
              status: _status,
              since: _clockInTime,
              location: clockedIn ? 'Head Office' : null,
            ),
            const SizedBox(height: 36),

            Center(
              child: ClockButton(
                clockedIn: clockedIn,
                busy: _busy,
                onPressed: _toggleClock,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                clockedIn ? 'Tap to end your shift' : 'Tap to start your shift',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 36),

            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Today',
                    value: _clockInTime == null
                        ? '—'
                        : DateFormatter.duration(now.difference(_clockInTime!)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatTile(label: 'This week', value: '32h 15m'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
