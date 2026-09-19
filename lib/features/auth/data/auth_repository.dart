import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/functions_client.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/secure_storage_services.dart';
import 'models/auth_response.dart';

/// The two ways a phone can be set up for quick sign-in.
enum QuickSignIn {
  biometric,
  pin;

  static QuickSignIn parse(String? value) =>
      value == 'pin' ? QuickSignIn.pin : QuickSignIn.biometric;

  String get wireName => name;
}

/// Kept so existing `catch (AuthException)` blocks still compile. New code
/// should catch [AppException], which carries the backend's error code.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

/// Identity, against Firebase Auth and the backend's callables.
///
/// Two ways in, and they are not variations of the same thing:
///
///   * **Password** — `signInWithEmailAndPassword`, straight to Firebase Auth.
///     We never see or transmit the password ourselves.
///   * **Biometric** — the OS checks the user's face or fingerprint, which
///     releases the device secret from the Keychain/Keystore; we present that
///     secret to `signInWithDevice` and get back a custom token. The biometric
///     itself never leaves the phone, so the app's privacy claim is literally
///     true. What the server verifies is possession of an enrolled device plus
///     a local user-presence check.
///
/// Neither path yields a token this class has to store. Firebase owns the
/// session; `authStateChanges()` is the source of truth.
class AuthRepository {
  const AuthRepository({
    FunctionsClient functions = const FunctionsClient(),
    SecureStorageService storage = const SecureStorageService(),
    BiometricService biometrics = const BiometricService(),
  }) : _functions = functions,
       _storage = storage,
       _biometrics = biometrics;

  final FunctionsClient _functions;
  final SecureStorageService _storage;
  final BiometricService _biometrics;

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Fires on sign-in, sign-out and token refresh. The app listens to this
  /// rather than tracking sessions itself.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ------------------------------------------------------------- password

  /// Signs in with an email address and password.
  ///
  /// Employee numbers are deliberately not accepted here. Firebase Auth
  /// identifies users by email, and the only way to accept `EMP-0042` would
  /// be a public endpoint that turns a staff number into an email address —
  /// which is a staff directory anyone can enumerate. The staff number is
  /// accepted on the biometric path instead, where it is useless without the
  /// device secret.
  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
  }) async {
    final String email = identifier.trim();
    if (!email.contains('@')) {
      throw const AuthException(
        'Please sign in with your work email address. Your employee number '
        'works once you have set up fingerprint or Face ID sign-in.',
        code: 'invalid-argument',
      );
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_passwordMessage(e), code: e.code, cause: e);
    }

    return loadProfile();
  }

  /// Creates the Firebase Auth user, then the `pending` employee profile.
  ///
  /// Order matters and is not negotiable: `createEmployeeProfile` is a
  /// callable that requires a signed-in caller, so the auth user must exist
  /// first. It is idempotent, so a retry after a dropped connection returns
  /// the existing profile instead of stranding the user with an email address
  /// they can no longer reuse.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? employeeId,
    String? phone,
    String? department,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // The address may belong to a sign-up that never finished (account
      // created, profile call lost) or to this very person on a new phone.
      // With the right password, carry on: createEmployeeProfile is
      // idempotent and returns the existing profile if there is one.
      if (e.code != 'email-already-in-use' ||
          !await _trySignIn(email.trim(), password)) {
        throw AuthException(_signUpMessage(e), code: e.code, cause: e);
      }
    }

    try {
      await _functions.call('createEmployeeProfile', <String, dynamic>{
        'fullName': fullName.trim(),
        if (employeeId != null && employeeId.trim().isNotEmpty)
          'employeeId': employeeId.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
      });
    } on AppException {
      // The auth user exists but has no profile — an unusable half-account.
      // Roll it back so the address stays available.
      await _cancelHalfFinishedSignUp();
      rethrow;
    }

    return loadProfile();
  }

  Future<bool> _trySignIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  /// See [SecureStorageService.markRegistered].
  Future<void> markRegistered() => _storage.markRegistered();

  Future<bool> isRegistered() => _storage.isRegistered();

  Future<void> _cancelHalfFinishedSignUp() async {
    try {
      await _functions.call('cancelSignUp');
    } catch (e) {
      debugPrint('cancelSignUp failed, leaving orphaned auth user: $e');
    }
  }

  /// Saves the caller's phone number and returns it as the backend stored it
  /// (spacing normalised).
  Future<String> updatePhone(String phone) async {
    final Map<String, dynamic> json = await _functions.call(
      'updateMyProfile',
      <String, dynamic>{'phone': phone.trim()},
    );
    return json['phone'] as String? ?? phone.trim();
  }

  /// Sends a password reset email. Never reveals whether the address exists.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw AuthException(
        e.message ?? 'Could not send the reset email. Please try again.',
        code: e.code,
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------- quick sign-in

  /// True when this phone has a secret bound to an account, so the login
  /// screen can offer the biometric button before anyone signs in.
  Future<bool> hasBiometricEnrollment() => _storage.hasBiometricEnrollment();

  Future<String?> enrolledDisplayName() => _storage.readEnrolledDisplayName();

  Future<String?> enrolledEmployeeId() => _storage.readEnrolledEmployeeId();

  /// How this phone signs in: [QuickSignIn.biometric] or [QuickSignIn.pin].
  Future<QuickSignIn> enrolledMethod() async =>
      QuickSignIn.parse(await _storage.readEnrolledMethod());

  /// Face ID, fingerprint, or nothing usable — drives the sign-up choice.
  Future<BiometricAvailability> biometricAvailability() =>
      _biometrics.availability();

  Future<BiometricKind> biometricKind() => _biometrics.primaryKind();

  /// Binds this device for quick sign-in: Face ID / fingerprint, or a PIN.
  ///
  /// Called while signed in — straight after sign-up (the account is still
  /// pending, which the backend allows) or later from Settings. A fresh
  /// device secret is generated here and stored in the Keychain/Keystore.
  ///
  /// * Biometric: the OS prompt must pass first; the server gets the secret
  ///   and keeps only its SHA-256.
  /// * PIN: no OS prompt. The server keeps an HMAC of the PIN keyed with the
  ///   secret, so signing in later needs both this phone and the PIN, and
  ///   five wrong PINs lock it.
  Future<AuthResponse> enrollQuickSignIn({
    required AuthResponse session,
    required QuickSignIn method,
    String? pin,
  }) async {
    if (method == QuickSignIn.biometric) {
      await _requireBiometricCheck(
        'Confirm it is you to turn on quick sign-in for MoTiroong.',
        cancelled: 'Setup was cancelled.',
      );
    }

    final String secret = SecureStorageService.generateDeviceSecret();
    final String deviceId = await _storage.deviceId();
    final BiometricKind kind = await _biometrics.primaryKind();
    final ({String platform, String model}) device = await _describeDevice();

    final Map<String, dynamic> result = await _functions
        .call('enrollDevice', <String, dynamic>{
          'deviceId': deviceId,
          'secret': secret,
          'platform': device.platform,
          'model': device.model,
          'method': method.wireName,
          if (method == QuickSignIn.biometric) 'biometricType': kind.wireName,
          if (method == QuickSignIn.pin) 'pin': pin,
        });

    // Written only after the backend has accepted the hash. The other order
    // leaves a secret on the phone that no server will ever recognise.
    await _storage.writeDeviceSecret(secret);
    await _storage.writeEnrollment(
      employeeId: session.employeeId,
      displayName: session.fullName,
      method: method.wireName,
    );

    return session.copyWith(
      biometricEnrolled: true,
      deviceCount: session.deviceCount + (result['enrolled'] == true ? 1 : 0),
    );
  }

  /// Signs in using the enrolled device.
  ///
  /// The OS prompt happens first and entirely on the phone. A pass releases
  /// the secret; the server hashes what we present and compares it in
  /// constant time. Five failures lock the device and force a password
  /// sign-in.
  Future<AuthResponse> signInWithBiometrics() async {
    await _requireBiometricCheck(
      'Sign in to MoTiroong',
      cancelled: 'Sign-in was cancelled.',
    );
    return _signInWithDevice();
  }

  /// Signs in on a PIN-enrolled device. The server checks the PIN against an
  /// HMAC keyed with this phone's secret; five wrong tries lock the device.
  Future<AuthResponse> signInWithPin(String pin) => _signInWithDevice(pin: pin);

  Future<AuthResponse> _signInWithDevice({String? pin}) async {
    final String? employeeId = await _storage.readEnrolledEmployeeId();
    final String? secret = await _storage.readDeviceSecret();
    if (employeeId == null || secret == null) {
      throw const AuthException(
        'Quick sign-in is not set up on this device yet.',
        code: 'not-enrolled',
      );
    }

    final String deviceId = await _storage.deviceId();
    final Map<String, dynamic> result = await _functions
        .call('signInWithDevice', <String, dynamic>{
          'employeeId': employeeId,
          'deviceId': deviceId,
          'secret': secret,
          if (pin != null) 'pin': pin,
        });

    final String? token = result['token'] as String?;
    if (token == null) {
      throw const AuthException(
        'Biometric sign-in could not be completed. Please use your password.',
        code: 'internal',
      );
    }

    // The custom token carries `biometric: true`, which is what lets clockIn
    // record that a shift was started from a verified session. The app cannot
    // assert that flag on its own, which is the point.
    await _auth.signInWithCustomToken(token);
    return loadProfile();
  }

  /// Forgets this device's binding locally and on the server.
  Future<void> revokeBiometrics() async {
    final String deviceId = await _storage.deviceId();
    try {
      await _functions.call('revokeDevice', <String, dynamic>{
        'deviceId': deviceId,
      });
    } on AppException catch (e) {
      // A device the server has already forgotten is still worth clearing here.
      if (e.code != 'not-found') rethrow;
    } finally {
      await _storage.clearBiometricEnrollment();
    }
  }

  /// Runs the OS prompt and turns its three outcomes into two.
  ///
  /// The prompt can pass, be dismissed, or fail for a device reason — no
  /// fingerprints enrolled, sensor locked out after too many attempts. Only
  /// the first is a success. The other two carry messages the user can act on,
  /// so they are translated here rather than left to escape as a
  /// `BiometricException` and surface as "something went wrong".
  Future<void> _requireBiometricCheck(
    String reason, {
    required String cancelled,
  }) async {
    final bool passed;
    try {
      passed = await _biometrics.authenticate(reason: reason);
    } on BiometricException catch (e) {
      throw AuthException(e.message, code: 'biometric-unavailable', cause: e);
    }
    if (!passed) throw AuthException(cancelled, code: 'aborted');
  }

  // -------------------------------------------------------------- profile

  /// Reads the caller's profile and approval state.
  ///
  /// Called after every sign-in and on resume. Status is re-read here rather
  /// than trusted from the ID token because claims lag by up to an hour, and
  /// an hour is long enough for a suspended employee to finish a shift.
  Future<AuthResponse> loadProfile() async {
    final Map<String, dynamic> json = await _functions.call('getMyProfile');
    return AuthResponse.fromJson(json);
  }

  Future<void> signOut() => _auth.signOut();

  /// Signs out and wipes the device binding — "this is not my phone any more".
  Future<void> signOutAndForgetDevice() async {
    await revokeBiometrics();
    await _auth.signOut();
  }

  // --------------------------------------------------------------- detail

  Future<({String platform, String model})> _describeDevice() async {
    final DeviceInfoPlugin info = DeviceInfoPlugin();
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IosDeviceInfo ios = await info.iosInfo;
        return (platform: 'ios', model: ios.utsname.machine);
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidDeviceInfo android = await info.androidInfo;
        return (
          platform: 'android',
          model: '${android.manufacturer} ${android.model}',
        );
      }
    } catch (e) {
      debugPrint('Could not read device info: $e');
    }
    return (platform: defaultTargetPlatform.name, model: 'Unknown device');
  }

  static String _passwordMessage(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Incorrect email address or password.',
    'invalid-email' => 'That does not look like a valid email address.',
    'user-disabled' =>
      'This account has been disabled. Please contact your administrator.',
    'too-many-requests' =>
      'Too many attempts. Wait a few minutes before trying again.',
    'network-request-failed' =>
      'Cannot reach MoTiroong. Check your connection and try again.',
    _ => e.message ?? 'Could not sign in. Please try again.',
  };

  static String _signUpMessage(FirebaseAuthException e) => switch (e.code) {
    'email-already-in-use' =>
      'That email address is already registered. Try signing in instead.',
    'invalid-email' => 'That does not look like a valid email address.',
    'weak-password' => 'Choose a password of at least 8 characters.',
    'operation-not-allowed' =>
      'Registration is closed. Please contact your administrator.',
    _ => e.message ?? 'Could not create your account. Please try again.',
  };
}
