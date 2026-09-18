import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';
import '../../domain/auth_state.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';

/// App-wide auth state. Listen with [ListenableBuilder].
///
/// The session is not something this class invents and holds — Firebase owns
/// it. This is a view over `authStateChanges()` plus the employee profile that
/// Firebase Auth does not model: the staff number, the role, and above all the
/// approval status, which is what decides whether a signed-in user sees the
/// clock or a "waiting for approval" screen.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? const AuthRepository();

  final AuthRepository _repository;

  AuthState _state = const AuthSignedOut();
  AuthState get state => _state;

  bool get isSignedIn => _state is AuthSignedIn;
  bool get isSigningIn => _state is AuthSigningIn;

  AuthResponse? get session =>
      _state is AuthSignedIn ? (_state as AuthSignedIn).session : null;

  String? get errorMessage =>
      _state is AuthFailure ? (_state as AuthFailure).message : null;

  /// Signed in, but the account is not `active`. The app should show the
  /// status screen — not the clock, and not an error.
  bool get awaitingApproval =>
      session != null && !session!.status.canClock;

  /// True when this phone has a device binding, so the login screen can offer
  /// the biometric button before anyone has signed in.
  Future<bool> get hasBiometricEnrollment =>
      _repository.hasBiometricEnrollment();

  Future<String?> get enrolledDisplayName => _repository.enrolledDisplayName();

  /// Restores a session on launch, from the splash screen.
  ///
  /// Firebase persists the session across restarts, so a returning user should
  /// not see the login screen at all. The profile is re-fetched rather than
  /// cached because status lives in custom claims, which lag by up to an hour
  /// — long enough for a suspended employee to work a full shift on a stale
  /// token.
  Future<void> restore() async {
    final User? user = _repository.currentUser;
    if (user == null) {
      _state = const AuthSignedOut();
      notifyListeners();
      return;
    }

    try {
      _state = AuthSignedIn(await _repository.loadProfile());
    } on AppException {
      // A session whose profile we cannot read is not a usable session.
      await _repository.signOut();
      _state = const AuthSignedOut();
    }
    notifyListeners();
  }

  /// Email-and-password sign-in.
  Future<void> signIn({
    required String identifier,
    required String password,
  }) => _attempt(
    () => _repository.signIn(identifier: identifier, password: password),
  );

  /// Biometric sign-in: the OS prompt releases the device secret, the server
  /// verifies it and mints a token that carries `biometric: true`.
  Future<void> signInWithBiometrics() =>
      _attempt(_repository.signInWithBiometrics);

  Future<void> _attempt(Future<AuthResponse> Function() action) async {
    _state = const AuthSigningIn();
    notifyListeners();
    try {
      _state = AuthSignedIn(await action());
    } on AppException catch (e) {
      // A cancelled biometric prompt is not a failure worth shouting about —
      // the user tapped away on purpose.
      _state = e.code == 'aborted'
          ? const AuthSignedOut()
          : AuthFailure(e.message);
    } catch (e) {
      debugPrint('Unhandled sign-in error: $e');
      _state = const AuthFailure(
        'Could not sign in. Check your connection and try again.',
      );
    }
    notifyListeners();
  }

  /// Turns on biometric sign-in for the signed-in employee.
  Future<bool> enrollBiometrics() async {
    final AuthResponse? current = session;
    if (current == null) return false;
    try {
      _state = AuthSignedIn(
        await _repository.enrollBiometrics(session: current),
      );
      notifyListeners();
      return true;
    } on AppException catch (e) {
      if (e.code != 'aborted') {
        _state = AuthFailure(e.message);
        notifyListeners();
      }
      return false;
    }
  }

  /// Re-reads the profile — after an admin approves the account, say.
  Future<void> refreshProfile() async {
    if (session == null) return;
    try {
      _state = AuthSignedIn(await _repository.loadProfile());
      notifyListeners();
    } on AppException {
      // Leave the last known profile in place rather than blanking the UI.
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    attendanceProvider.reset();
    _state = const AuthSignedOut();
    notifyListeners();
  }

  /// Signs out and removes this device's biometric binding — for "this is not
  /// my phone any more", not for an ordinary sign-out.
  Future<void> signOutAndForgetDevice() async {
    await _repository.signOutAndForgetDevice();
    attendanceProvider.reset();
    _state = const AuthSignedOut();
    notifyListeners();
  }
}

/// Single app-wide instance.
final AuthProvider authProvider = AuthProvider();
