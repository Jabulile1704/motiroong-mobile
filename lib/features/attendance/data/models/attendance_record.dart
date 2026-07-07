/// Current clocking state of the signed-in employee.
enum ClockStatus {
  clockedIn,
  clockedOut,
  onBreak;

  String get label => switch (this) {
        ClockStatus.clockedIn => 'Clocked in',
        ClockStatus.clockedOut => 'Clocked out',
        ClockStatus.onBreak => 'On break',
      };
}

/// A single day's attendance entry.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.clockIn,
    this.clockOut,
    this.location,
  });

  final String id;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? location;

  bool get isComplete => clockOut != null;

  Duration get workedDuration =>
      (clockOut ?? DateTime.now()).difference(clockIn);

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      clockIn: DateTime.parse(json['clock_in'] as String),
      clockOut: json['clock_out'] != null
          ? DateTime.parse(json['clock_out'] as String)
          : null,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clock_in': clockIn.toIso8601String(),
        'clock_out': clockOut?.toIso8601String(),
        'location': location,
      };
}
