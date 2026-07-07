import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_button.dart';

enum _ExceptionType { lateArrival, absence, earlyLeave }

/// Requests tab: submit an attendance exception (late arrival, absence,
/// early leave) using iOS grouped-form styling.
class ExceptionRequestScreen extends StatefulWidget {
  const ExceptionRequestScreen({super.key});

  @override
  State<ExceptionRequestScreen> createState() => _ExceptionRequestScreenState();
}

class _ExceptionRequestScreenState extends State<ExceptionRequestScreen> {
  _ExceptionType _type = _ExceptionType.lateArrival;
  DateTime _date = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime selected = _date;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6),
        color: AppColors.card(Theme.of(context).brightness),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date,
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  onDateTimeChanged: (value) => selected = value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => _date = selected);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    // Placeholder for the real exceptions API call.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    _reasonController.clear();
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Request submitted'),
        content: const Text(
            'Your request has been sent to your manager for approval.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Brightness brightness = theme.brightness;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Requests')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            20, 8, 20, AppConstants.bottomBarClearance),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'REQUEST TYPE',
              style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<_ExceptionType>(
              groupValue: _type,
              onValueChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
              children: const {
                _ExceptionType.lateArrival: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Late'),
                ),
                _ExceptionType.absence: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Absence'),
                ),
                _ExceptionType.earlyLeave: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Early leave'),
                ),
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'DETAILS',
              style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.5),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.calendar),
                  title: const Text('Date'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormatter.shortDate(_date),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondaryLabel(brightness),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 18,
                        color: AppColors.secondaryLabel(brightness),
                      ),
                    ],
                  ),
                  onTap: _pickDate,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Divider(),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CupertinoTextField(
                    controller: _reasonController,
                    placeholder: 'Reason (optional)',
                    maxLines: 4,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fill(brightness),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'Submit Request',
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
