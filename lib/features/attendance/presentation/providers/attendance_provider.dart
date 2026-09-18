import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/services/location_service.dart';
import '../../data/attendance_repository.dart';
import '../../data/models/attendance_record.dart';

/// Clock state for the home and history screens.
///
/// The provider never decides anything about a shift. It captures a geo-tag,
/// hands it to the backend and displays the verdict that comes back — which is
/// why [lastResult] is kept separately from [state]: a clock-in can succeed
/// *and* come back flagged, and the UI has to say both.
class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({
    AttendanceRepository? repository,
    LocationService? location,
  }) : _repository = repository ?? const AttendanceRepository(),
       _location = location ?? const LocationService();

  final AttendanceRepository _repository;
  final LocationService _location;

  ClockState _state = const ClockState.clockedOut();
  ClockState get state => _state;

  bool get isClockedIn => _state.clockedIn;

  bool _busy = false;
  bool get isBusy => _busy;

  String? _error;
  String? get error => _error;

  /// The outcome of the most recent clock action, so the screen can show
  /// "Clocked in — 40 m outside Bloemfontein Depot" rather than just a tick.
  ClockResult? _lastResult;
  ClockResult? get lastResult => _lastResult;

  List<AttendanceRecord> _history = const <AttendanceRecord>[];
  List<AttendanceRecord> get history => _history;
  bool _hasMoreHistory = false;
  bool get hasMoreHistory => _hasMoreHistory;

  /// Called when the home screen appears and on resume.
  Future<void> refresh() async {
    try {
      _state = await _repository.getClockStatus();
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  /// Captures a fix and opens a shift.
  ///
  /// Returns the server's verdict, or null if the attempt failed outright.
  /// A flagged-but-recorded clock-in is a success, not a failure — check
  /// `result.isFlagged` rather than treating a non-null return as "all clear".
  Future<ClockResult?> clockIn() => _clock(_repository.clockIn);

  Future<ClockResult?> clockOut() => _clock(_repository.clockOut);

  Future<ClockResult?> _clock(
    Future<ClockResult> Function({required LocationResult location}) action,
  ) async {
    if (_busy) return null;
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      // The fix is taken here rather than cached, so the geo-tag belongs to
      // the moment of the tap. A stale position is the one thing that would
      // make the whole geofence exercise meaningless.
      final LocationResult location = await _location.getCurrentLocation();
      final ClockResult result = await action(location: location);

      _lastResult = result;
      _state = await _repository.getClockStatus();
      return result;
    } on LocationException catch (e) {
      _error = e.message;
      return null;
    } on AppException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// First page of history. Call [loadMoreHistory] for the rest.
  Future<void> loadHistory() async {
    try {
      final result = await _repository.history();
      _history = result.records;
      _hasMoreHistory = result.hasMore;
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  Future<void> loadMoreHistory() async {
    if (!_hasMoreHistory || _history.isEmpty) return;
    try {
      final result = await _repository.history(
        before: _history.last.clockInAt,
      );
      _history = <AttendanceRecord>[..._history, ...result.records];
      _hasMoreHistory = result.hasMore;
    } on AppException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }

  /// Files an explanation for a flagged event.
  Future<bool> submitException({
    required String type,
    required String reason,
    String? attendanceId,
  }) async {
    try {
      await _repository.submitException(
        type: type,
        reason: reason,
        attendanceId: attendanceId,
      );
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clears everything on sign-out so the next user never sees the last
  /// user's shifts.
  void reset() {
    _state = const ClockState.clockedOut();
    _history = const <AttendanceRecord>[];
    _lastResult = null;
    _error = null;
    _hasMoreHistory = false;
    notifyListeners();
  }
}

/// Single app-wide instance, matching the `authProvider` pattern.
final AttendanceProvider attendanceProvider = AttendanceProvider();
