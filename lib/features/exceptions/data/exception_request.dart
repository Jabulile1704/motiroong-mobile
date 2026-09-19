/// What an exception request is about. Mirrors `EXCEPTION_TYPES` in
/// `motiroong-backend/functions/src/exceptions/exceptions.ts`.
enum ExceptionType {
  lateArrival('late_arrival', 'Late'),
  earlyLeave('early_leave', 'Early leave'),
  absence('absence', 'Absence'),
  missedClockIn('missed_clock_in', 'Missed clock-in'),
  missedClockOut('missed_clock_out', 'Missed clock-out'),
  outsideGeofence('outside_geofence', 'Off site'),
  deviceFailure('device_failure', 'Device problem'),
  other('other', 'Other');

  const ExceptionType(this.wireName, this.label);

  final String wireName;
  final String label;

  static ExceptionType parse(String? value) => ExceptionType.values.firstWhere(
    (t) => t.wireName == value,
    orElse: () => ExceptionType.other,
  );
}

enum ExceptionStatus {
  pending,
  approved,
  rejected;

  static ExceptionStatus parse(String? value) => switch (value) {
    'approved' => ExceptionStatus.approved,
    'rejected' => ExceptionStatus.rejected,
    _ => ExceptionStatus.pending,
  };

  String get label => switch (this) {
    ExceptionStatus.pending => 'Pending',
    ExceptionStatus.approved => 'Approved',
    ExceptionStatus.rejected => 'Denied',
  };
}

/// One of the employee's requests, as `listMyExceptions` returns it.
class ExceptionRequest {
  const ExceptionRequest({
    required this.exceptionId,
    required this.type,
    required this.reason,
    required this.status,
    this.forDate,
    this.attendanceId,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNotes,
  });

  final String exceptionId;
  final ExceptionType type;
  final String reason;
  final ExceptionStatus status;

  /// The calendar day the request is about, when the employee gave one.
  final DateTime? forDate;
  final String? attendanceId;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  /// The reviewer's note, shown to the employee alongside the decision.
  final String? reviewNotes;

  factory ExceptionRequest.fromJson(Map<String, dynamic> json) =>
      ExceptionRequest(
        exceptionId: json['exceptionId'] as String? ?? '',
        type: ExceptionType.parse(json['type'] as String?),
        reason: json['reason'] as String? ?? '',
        status: ExceptionStatus.parse(json['status'] as String?),
        // A calendar date: parse as local midnight, not as a UTC instant.
        forDate: _parseDay(json['forDate']),
        attendanceId: json['attendanceId'] as String?,
        submittedAt: _parseInstant(json['submittedAt']),
        reviewedAt: _parseInstant(json['reviewedAt']),
        reviewNotes: json['reviewNotes'] as String?,
      );
}

/// `YYYY-MM-DD` for the backend's `forDate`.
String wireDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _parseDay(dynamic value) {
  if (value is! String) return null;
  final List<String> p = value.split('-');
  if (p.length != 3) return null;
  final int? y = int.tryParse(p[0]),
      m = int.tryParse(p[1]),
      d = int.tryParse(p[2]);
  return y == null || m == null || d == null ? null : DateTime(y, m, d);
}

DateTime? _parseInstant(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
