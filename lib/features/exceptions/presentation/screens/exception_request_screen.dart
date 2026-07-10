import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/moti_icons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum _ExceptionType {
  lateArrival('Late'),
  absence('Absence'),
  earlyLeave('Early Leave');

  const _ExceptionType(this.label);
  final String label;
}

enum _RequestStatus { approved, pending, denied }

class _ExceptionRequest {
  const _ExceptionRequest({
    required this.title,
    required this.reason,
    required this.status,
  });

  final String title;
  final String reason;
  final _RequestStatus status;
}

/// Exceptions, per the app-screens handoff: the new-request form
/// (segmented type, date pill, reason field, dark submit) and the
/// Recent list using the fill/outline/faded status language.
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

  final List<_ExceptionRequest> _recent = [
    const _ExceptionRequest(
      title: 'Late — Jul 3',
      reason: 'Traffic delay',
      status: _RequestStatus.approved,
    ),
    const _ExceptionRequest(
      title: 'Early Leave — Jun 28',
      reason: 'Medical appointment',
      status: _RequestStatus.pending,
    ),
    const _ExceptionRequest(
      title: 'Absence — Jun 14',
      reason: 'No documentation provided',
      status: _RequestStatus.denied,
    ),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    DateTime selected = _date;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6),
        color: p.card,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done', style: TextStyle(color: p.ink)),
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
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    // Placeholder for the real exceptions API call.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final String reason = _reasonController.text.trim();
    setState(() {
      _submitting = false;
      _recent.insert(
        0,
        _ExceptionRequest(
          title:
              '${_type.label} — ${DateFormatter.shortDate(_date).split(',').first}',
          reason: reason.isEmpty ? 'No reason provided' : reason,
          status: _RequestStatus.pending,
        ),
      );
      _reasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );

    return Scaffold(
      backgroundColor: p.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 14,
          20,
          108,
        ),
        children: [
          ScreenHeader(initials: authProvider.session?.initials ?? 'JS'),
          const SizedBox(height: 26),
          const SectionEyebrow('Requests'),
          const SizedBox(height: 6),
          const ScreenTitle('Exceptions'),
          const SizedBox(height: 20),
          BrandCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('New request'),
                const SizedBox(height: 12),
                _buildSegmentedControl(p),
                const SizedBox(height: 16),
                _fieldLabel('Date', p),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: p.field,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.shortDate(_date),
                          style: TextStyle(
                            fontFamily: Brand.wordmarkFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: p.ink,
                          ),
                        ),
                        const MotiIcon(
                          MotiGlyph.calendar,
                          size: 16,
                          color: Brand.placeholderGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _fieldLabel('Reason', p),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: p.field,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: TextField(
                    controller: _reasonController,
                    enabled: !_submitting,
                    minLines: 3,
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 13,
                      color: p.ink,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Explain what happened…',
                      hintStyle: TextStyle(
                        fontFamily: Brand.wordmarkFont,
                        fontSize: 13,
                        color: Brand.placeholderGrey,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _submitting
                        ? CupertinoActivityIndicator(color: p.onInk)
                        : Text(
                            'Submit Exception',
                            style: TextStyle(
                              fontFamily: Brand.wordmarkFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: p.onInk,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Recent'),
          const SizedBox(height: 10),
          for (final _ExceptionRequest r in _recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RequestRow(request: r),
            ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, BrandPalette p) => Text(
    text,
    style: TextStyle(
      fontFamily: Brand.wordmarkFont,
      fontSize: 12,
      color: p.muted,
    ),
  );

  Widget _buildSegmentedControl(BrandPalette p) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final _ExceptionType t in _ExceptionType.values) ...[
            if (t != _ExceptionType.values.first) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _type == t ? p.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.label,
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _type == t ? p.onInk : p.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final _ExceptionRequest request;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final bool denied = request.status == _RequestStatus.denied;

    final StatusPill pill = switch (request.status) {
      _RequestStatus.approved => const StatusPill(
        'Approved',
        style: StatusPillStyle.inverse,
      ),
      _RequestStatus.pending => const StatusPill(
        'Pending',
        style: StatusPillStyle.outlined,
      ),
      _RequestStatus.denied => const StatusPill(
        'Denied',
        style: StatusPillStyle.faded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: denied ? p.faded : p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.reason,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 12,
                    color: denied ? p.faded : p.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          pill,
        ],
      ),
    );
  }
}
