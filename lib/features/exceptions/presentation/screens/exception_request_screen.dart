import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/brand.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/moti_icons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/exception_request.dart';

/// Exceptions, per the app-screens handoff: the new-request form (type,
/// date pill, reason field, dark submit) and the Recent list using the
/// fill/outline/faded status language.
///
/// Requests go to `submitException` and are reviewed by a supervisor or
/// admin in the admin dashboard; Recent is `listMyExceptions`, so a decision
/// shows up here with the reviewer's note.
class ExceptionRequestScreen extends StatefulWidget {
  const ExceptionRequestScreen({super.key});

  @override
  State<ExceptionRequestScreen> createState() => _ExceptionRequestScreenState();
}

class _ExceptionRequestScreenState extends State<ExceptionRequestScreen> {
  /// The backend insists on this much, so a reviewer has something to act on.
  static const int _minReason = 10;

  ExceptionType _type = ExceptionType.lateArrival;
  DateTime _date = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    attendanceProvider.addListener(_changed);
    _reasonController.addListener(_changed);
    if (!attendanceProvider.exceptionsLoaded) {
      attendanceProvider.loadExceptions();
    }
  }

  @override
  void dispose() {
    attendanceProvider.removeListener(_changed);
    _reasonController.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit =>
      !_submitting && _reasonController.text.trim().length >= _minReason;

  Future<void> _pickDate() async {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final DateTime now = DateTime.now();
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
                  // The backend accepts a year back and 60 days ahead.
                  minimumDate: now.subtract(const Duration(days: 365)),
                  maximumDate: now.add(const Duration(days: 60)),
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
    final bool ok = await attendanceProvider.submitException(
      type: _type,
      reason: _reasonController.text.trim(),
      forDate: _date,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    final String message = ok
        ? 'Request sent. Your supervisor will review it.'
        : attendanceProvider.error ?? 'Could not send the request.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) {
      _reasonController.clear();
      setState(() {
        _type = ExceptionType.lateArrival;
        _date = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final List<ExceptionRequest> recent = attendanceProvider.exceptions;
    final int typed = _reasonController.text.trim().length;

    return Scaffold(
      backgroundColor: p.background,
      body: RefreshIndicator(
        color: p.ink,
        onRefresh: attendanceProvider.loadExceptions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 14,
            20,
            108,
          ),
          children: [
            ScreenHeader(initials: authProvider.session?.initials),
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
                  _buildTypeChips(p),
                  const SizedBox(height: 16),
                  _fieldLabel('Date', p),
                  const SizedBox(height: 6),
                  Semantics(
                    button: true,
                    label: 'Date, ${DateFormatter.shortDate(_date)}',
                    child: GestureDetector(
                      onTap: _submitting ? null : _pickDate,
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
                      maxLines: 5,
                      maxLength: 1000,
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
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (typed > 0 && typed < _minReason) ...[
                    const SizedBox(height: 6),
                    Text(
                      'A few more words, please (at least $_minReason characters).',
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    enabled: _canSubmit,
                    child: GestureDetector(
                      onTap: _canSubmit ? _submit : null,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _canSubmit || _submitting ? 1 : 0.45,
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Recent'),
            const SizedBox(height: 10),
            if (!attendanceProvider.exceptionsLoaded)
              const Center(child: CupertinoActivityIndicator())
            else if (recent.isEmpty)
              Text(
                'No requests yet.',
                style: TextStyle(fontSize: 13, color: p.muted),
              )
            else
              for (final ExceptionRequest r in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RequestRow(request: r),
                ),
          ],
        ),
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

  /// Every request type the backend accepts, as a wrap of pills.
  Widget _buildTypeChips(BrandPalette p) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final ExceptionType t in ExceptionType.values)
          Semantics(
            button: true,
            selected: _type == t,
            child: GestureDetector(
              onTap: _submitting ? null : () => setState(() => _type = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _type == t ? p.ink : p.field,
                  borderRadius: BorderRadius.circular(20),
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
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final ExceptionRequest request;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    final ExceptionRequest r = request;
    final bool denied = r.status == ExceptionStatus.rejected;
    final DateTime? day = r.forDate ?? r.submittedAt;
    final String title = day == null
        ? r.type.label
        : '${r.type.label} — ${DateFormatter.shortDate(day).split(',').first}';

    final StatusPill pill = switch (r.status) {
      ExceptionStatus.approved => const StatusPill(
        'Approved',
        style: StatusPillStyle.inverse,
      ),
      ExceptionStatus.pending => const StatusPill(
        'Pending',
        style: StatusPillStyle.outlined,
      ),
      ExceptionStatus.rejected => const StatusPill(
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: denied ? p.faded : p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Brand.wordmarkFont,
                    fontSize: 12,
                    color: denied ? p.faded : p.muted,
                  ),
                ),
                if (r.reviewNotes != null && r.reviewNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reviewer: ${r.reviewNotes}',
                    style: TextStyle(
                      fontFamily: Brand.wordmarkFont,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: p.ink,
                    ),
                  ),
                ],
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
