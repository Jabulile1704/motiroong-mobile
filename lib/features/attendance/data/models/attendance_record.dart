/// Why a clock event was flagged.
///
/// Mirrors `AttendanceFlag` in `motiroong-backend/functions/src/types.ts`. A
/// flagged event is still a recorded event — the employee may have a perfectly
/// good reason — so these drive an explanation prompt, never a refusal.
enum AttendanceFlag {
  outsideGeofence,
  lowGpsAccuracy,
  clockSkew,
  lateSync,
  noBiometric,
  autoClosed,
  unknown;

  static AttendanceFlag parse(String? value) => switch (value) {
    'outside_geofence' => AttendanceFlag.outsideGeofence,
    'low_gps_accuracy' => AttendanceFlag.lowGpsAccuracy,
    'clock_skew' => AttendanceFlag.clockSkew,
    'late_sync' => AttendanceFlag.lateSync,
    'no_biometric' => AttendanceFlag.noBiometric,
    'auto_closed' => AttendanceFlag.autoClosed,
    _ => AttendanceFlag.unknown,
  };

  /// Short text for the badge on a history row.
  String get label => switch (this) {
    AttendanceFlag.outsideGeofence => 'Off site',
    AttendanceFlag.lowGpsAccuracy => 'Weak GPS',
    AttendanceFlag.clockSkew => 'Clock mismatch',
    AttendanceFlag.lateSync => 'Synced late',
    AttendanceFlag.noBiometric => 'No biometric',
    AttendanceFlag.autoClosed => 'Auto-closed',
    AttendanceFlag.unknown => 'Flagged',
  };

  /// What the employee should be told, phrased as a fact rather than an
  /// accusation — a supervisor decides what it means, not the app.
  String get explanation => switch (this) {
    AttendanceFlag.outsideGeofence =>
      'This was recorded outside your site boundary.',
    AttendanceFlag.lowGpsAccuracy =>
      'Your GPS signal was too weak to confirm the location.',
    AttendanceFlag.clockSkew =>
      'Your phone clock disagreed with the server clock.',
    AttendanceFlag.lateSync => 'This was submitted well after the event.',
    AttendanceFlag.noBiometric =>
      'This shift was started without fingerprint or Face ID.',
    AttendanceFlag.autoClosed =>
      'Nobody clocked out, so the shift was closed automatically.',
    AttendanceFlag.unknown => 'This entry needs review.',
  };

  /// Worth offering the employee an exception request.
  bool get invitesExplanation =>
      this == AttendanceFlag.outsideGeofence ||
      this == AttendanceFlag.autoClosed ||
      this == AttendanceFlag.lowGpsAccuracy;
}

/// Current clock state, as `getClockStatus` returns it.
class ClockState {
  const ClockState({
    required this.clockedIn,
    this.recordId,
    this.since,
    this.elapsedMinutes = 0,
    this.siteId,
    this.flags = const <AttendanceFlag>[],
  });

  const ClockState.clockedOut() : this(clockedIn: false);

  final bool clockedIn;
  final String? recordId;

  /// Server time the open shift started. Elapsed time is computed from this
  /// rather than from the phone clock, which is the whole point.
  final DateTime? since;
  final int elapsedMinutes;
  final String? siteId;
  final List<AttendanceFlag> flags;

  Duration get elapsed => since != null
      ? DateTime.now().toUtc().difference(since!.toUtc())
      : Duration(minutes: elapsedMinutes);

  String get label => clockedIn ? 'Clocked in' : 'Clocked out';

  factory ClockState.fromJson(Map<String, dynamic> json) => ClockState(
    clockedIn: json['clockedIn'] as bool? ?? false,
    recordId: json['recordId'] as String?,
    since: _parseDate(json['since']),
    elapsedMinutes: (json['elapsedMinutes'] as num?)?.toInt() ?? 0,
    siteId: json['siteId'] as String?,
    flags: _parseFlags(json['flags']),
  );
}

/// One attendance entry, in the shape `summarise()` sends on the wire.
class AttendanceRecord {
  const AttendanceRecord({
    required this.recordId,
    required this.employeeId,
    required this.status,
    required this.clockInAt,
    this.clockOutAt,
    this.siteId,
    this.durationMinutes,
    this.clockInDistanceMeters,
    this.clockOutDistanceMeters,
    this.clockInBiometric = false,
    this.clockOutBiometric = false,
    this.flags = const <AttendanceFlag>[],
  });

  final String recordId;
  final String employeeId;

  /// `open` while the shift is running, `closed` once clocked out.
  final String status;

  /// Server timestamps, both of them. A phone with its clock wound back
  /// cannot move these.
  final DateTime clockInAt;
  final DateTime? clockOutAt;

  final String? siteId;

  /// Computed server-side on clock-out. Null while the shift is open.
  final int? durationMinutes;

  final double? clockInDistanceMeters;
  final double? clockOutDistanceMeters;
  final bool clockInBiometric;
  final bool clockOutBiometric;
  final List<AttendanceFlag> flags;

  bool get isOpen => status == 'open';
  bool get isComplete => clockOutAt != null;
  bool get isFlagged => flags.isNotEmpty;

  /// For an open shift this ticks; for a closed one it is the stored figure.
  Duration get workedDuration => durationMinutes != null
      ? Duration(minutes: durationMinutes!)
      : DateTime.now().toUtc().difference(clockInAt.toUtc());

  /// The flag most worth surfacing on a crowded history row.
  AttendanceFlag? get primaryFlag => flags.isEmpty ? null : flags.first;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        recordId: json['recordId'] as String? ?? '',
        employeeId: json['employeeId'] as String? ?? '',
        status: json['status'] as String? ?? 'closed',
        clockInAt: _parseDate(json['clockInAt']) ?? DateTime.now(),
        clockOutAt: _parseDate(json['clockOutAt']),
        siteId: json['siteId'] as String?,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        clockInDistanceMeters: (json['clockInDistanceMeters'] as num?)
            ?.toDouble(),
        clockOutDistanceMeters: (json['clockOutDistanceMeters'] as num?)
            ?.toDouble(),
        clockInBiometric: json['clockInBiometric'] as bool? ?? false,
        clockOutBiometric: json['clockOutBiometric'] as bool? ?? false,
        flags: _parseFlags(json['flags']),
      );
}

/// The outcome of a clock-in or clock-out, as the buttons need it.
class ClockResult {
  const ClockResult({
    required this.recordId,
    required this.status,
    this.siteName,
    this.distanceMeters,
    this.insideGeofence = true,
    this.durationMinutes,
    this.duplicate = false,
    this.flags = const <AttendanceFlag>[],
  });

  final String recordId;
  final String status;
  final String? siteName;
  final double? distanceMeters;

  /// The server's verdict, not the app's guess.
  final bool insideGeofence;
  final int? durationMinutes;

  /// A double tap or an offline replay returned the existing record.
  final bool duplicate;
  final List<AttendanceFlag> flags;

  bool get isFlagged => flags.isNotEmpty;

  factory ClockResult.fromJson(Map<String, dynamic> json) => ClockResult(
    recordId: json['recordId'] as String? ?? '',
    status: json['status'] as String? ?? 'open',
    siteName: json['siteName'] as String?,
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    insideGeofence: json['insideGeofence'] as bool? ?? true,
    durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    duplicate: json['duplicate'] as bool? ?? false,
    flags: _parseFlags(json['flags']),
  );
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

List<AttendanceFlag> _parseFlags(dynamic value) => value is List
    ? value.map((f) => AttendanceFlag.parse(f as String?)).toList()
    : const <AttendanceFlag>[];
