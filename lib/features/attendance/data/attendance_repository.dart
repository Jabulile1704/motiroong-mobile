import '../../../core/network/functions_client.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/secure_storage_services.dart';
import '../../exceptions/data/exception_request.dart';
import 'models/attendance_record.dart';

/// Clocking, history and exception requests.
///
/// Every method here is a callable. That is not indirection for its own sake:
/// the app is not permitted to write to `attendance/` at all — `firestore.rules`
/// denies client writes outright — because an attendance record is only worth
/// something if the device that benefits from it cannot author it. The app
/// asks to clock in; it does not record that it did.
///
/// Two consequences worth remembering while reading the UI code:
///
///   * The times in every response are **server** times. The phone's clock is
///     sent along and compared, but it never decides anything.
///   * `insideGeofence` is the server's verdict, recomputed from the site
///     record. The green dot on the home screen before you tap is a courtesy.
class AttendanceRepository {
  const AttendanceRepository({
    FunctionsClient functions = const FunctionsClient(),
    SecureStorageService storage = const SecureStorageService(),
  }) : _functions = functions,
       _storage = storage;

  final FunctionsClient _functions;
  final SecureStorageService _storage;

  /// Current state for the home screen.
  Future<ClockState> getClockStatus() async {
    final Map<String, dynamic> json = await _functions.call('getClockStatus');
    return ClockState.fromJson(json);
  }

  /// Opens a shift.
  ///
  /// Being outside the geofence does not fail this call — it comes back with
  /// `insideGeofence: false` and an `outsideGeofence` flag, and the employee
  /// is invited to explain. Refusing would leave someone legitimately off-site
  /// with no way to record that they worked, and the usual result of that is a
  /// paper note nobody reconciles.
  Future<ClockResult> clockIn({required LocationResult location}) async {
    final Map<String, dynamic> json = await _functions.call(
      'clockIn',
      <String, dynamic>{
        'location': _geoPoint(location),
        'deviceId': await _storage.deviceId(),
      },
    );
    return ClockResult.fromJson(json);
  }

  /// Closes the open shift. Duration is computed from the two server
  /// timestamps, so it cannot be inflated from the phone.
  Future<ClockResult> clockOut({required LocationResult location}) async {
    final Map<String, dynamic> json = await _functions.call(
      'clockOut',
      <String, dynamic>{
        'location': _geoPoint(location),
        'deviceId': await _storage.deviceId(),
      },
    );
    return ClockResult.fromJson(json);
  }

  /// One page of the caller's own history, newest first.
  ///
  /// [before] is the `clockInAt` of the last row you already have — pass it to
  /// fetch the next page.
  Future<({List<AttendanceRecord> records, bool hasMore})> history({
    int limit = 30,
    DateTime? before,
  }) async {
    final Map<String, dynamic> json = await _functions.call(
      'getAttendanceHistory',
      <String, dynamic>{
        'limit': limit,
        if (before != null) 'before': before.toUtc().toIso8601String(),
      },
    );

    final List<dynamic> raw = json['records'] as List<dynamic>? ?? const [];
    return (
      records: raw
          .map(
            (r) =>
                AttendanceRecord.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  /// A single record — used by the exception screen to show what is being
  /// explained.
  Future<AttendanceRecord> record(String recordId) async {
    final Map<String, dynamic> json = await _functions.call(
      'getAttendanceRecord',
      <String, dynamic>{'recordId': recordId},
    );
    return AttendanceRecord.fromJson(json);
  }

  /// The active site geofences, so the app can show the user where they are
  /// relative to their site before they tap.
  Future<List<SiteSummary>> sites() async {
    final Map<String, dynamic> json = await _functions.call('listSites');
    final List<dynamic> raw = json['sites'] as List<dynamic>? ?? const [];
    return raw
        .map((s) => SiteSummary.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
  }

  /// Files an explanation for a flagged or missing event.
  ///
  /// [type] is one of `missed_clock_in`, `outside_geofence`, `device_failure`,
  /// `other`. [reason] must be at least 10 characters — the backend enforces
  /// that, because a one-word reason is not a reason a supervisor can act on.
  Future<String> submitException({
    required ExceptionType type,
    required String reason,
    DateTime? forDate,
    String? attendanceId,
  }) async {
    final Map<String, dynamic> json = await _functions
        .call('submitException', <String, dynamic>{
          'type': type.wireName,
          'reason': reason,
          if (forDate != null) 'forDate': wireDay(forDate),
          if (attendanceId != null) 'attendanceId': attendanceId,
        });
    return json['exceptionId'] as String? ?? '';
  }

  /// The caller's own exception requests and where each one stands.
  Future<List<ExceptionRequest>> myExceptions({int limit = 30}) async {
    final Map<String, dynamic> json = await _functions.call(
      'listMyExceptions',
      <String, dynamic>{'limit': limit},
    );
    final List<dynamic> raw = json['exceptions'] as List<dynamic>? ?? const [];
    return raw
        .map(
          (e) => ExceptionRequest.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// The wire shape `parseGeoPoint` expects. `capturedAt` is the phone's own
  /// clock and is treated as untrusted on the far side — it exists so that a
  /// disagreement with the server clock can be flagged, not so that it can be
  /// believed.
  static Map<String, dynamic> _geoPoint(LocationResult location) =>
      <String, dynamic>{
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracyMeters': location.accuracyMeters,
        'capturedAt': location.timestamp.toUtc().toIso8601String(),
      };
}

/// A site geofence as `listSites` returns it.
class SiteSummary {
  const SiteSummary({
    required this.siteId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.address,
  });

  final String siteId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? address;

  factory SiteSummary.fromJson(Map<String, dynamic> json) => SiteSummary(
    siteId: json['siteId'] as String? ?? '',
    name: json['name'] as String? ?? 'Unnamed site',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150,
    address: json['address'] as String?,
  );
}
