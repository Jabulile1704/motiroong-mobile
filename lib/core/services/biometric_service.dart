import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// What the device can do, and whether the user has set it up.
enum BiometricAvailability {
  /// A sensor exists and the user has enrolled a face or finger.
  ready,

  /// Hardware exists, but nothing is enrolled in the OS yet — the user has
  /// to add a fingerprint or Face ID in Settings first.
  notEnrolled,

  /// No sensor, or the platform does not support it (Flutter web).
  unsupported,

  /// Locked out after too many failed attempts; the OS wants a passcode.
  lockedOut,
}

/// Which sensor the device leads with — drives the icon and the wording,
/// since "Use Face ID" on a fingerprint-only phone is just confusing.
enum BiometricKind { face, fingerprint, iris, none }

/// "Face ID" is Apple's name; Android calls the same thing face unlock.
bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

/// What to call biometrics before the device has been asked which sensor it
/// has: Face ID on iPhone, Fingerprint on Android.
String defaultBiometricTitle() => _isIOS ? 'Face ID' : 'Fingerprint';

extension BiometricKindLabel on BiometricKind {
  /// Sentence-case, for body copy: "Sign in with your fingerprint".
  String get label => switch (this) {
    BiometricKind.face => _isIOS ? 'Face ID' : 'face unlock',
    BiometricKind.fingerprint => 'fingerprint',
    BiometricKind.iris => 'iris scan',
    BiometricKind.none => 'biometrics',
  };

  /// Capitalised, for buttons and headings.
  String get title => switch (this) {
    BiometricKind.face => _isIOS ? 'Face ID' : 'Face unlock',
    BiometricKind.fingerprint => 'Fingerprint',
    BiometricKind.iris => 'Iris',
    BiometricKind.none => 'Biometrics',
  };

  /// The value sent to `enrollDevice`, recorded for the audit trail.
  String get wireName => switch (this) {
    BiometricKind.face => 'face',
    BiometricKind.fingerprint => 'fingerprint',
    BiometricKind.iris => 'iris',
    BiometricKind.none => 'unknown',
  };
}

class BiometricException implements Exception {
  const BiometricException(this.message, {this.availability});

  final String message;
  final BiometricAvailability? availability;

  @override
  String toString() => message;
}

/// Wraps `local_auth`.
///
/// Worth being precise about what this does, because "biometric login"
/// suggests something it is not: **nothing here authenticates the user to
/// the server.** The OS checks the face or fingerprint locally and hands
/// back a single boolean. The app never sees biometric data — it stays in
/// the Secure Enclave / TEE, where no app can read it.
///
/// What a successful check is *for* is releasing the device secret from the
/// Keychain (see [SecureStorageService]). That secret is what the backend
/// verifies. The chain is:
///
///   face/finger → OS says yes → secret released → server verifies secret
///
/// which is why passing the biometric check on a phone that was never
/// enrolled gets you nowhere.
class BiometricService {
  const BiometricService();

  static final LocalAuthentication _auth = LocalAuthentication();

  /// What this device is capable of right now.
  Future<BiometricAvailability> availability() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return BiometricAvailability.unsupported;
      }
      if (!await _auth.canCheckBiometrics) {
        return BiometricAvailability.unsupported;
      }
      final List<BiometricType> enrolled =
          await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.ready;
    } on LocalAuthException catch (e) {
      return _availabilityFor(e.code) ?? BiometricAvailability.unsupported;
    } on MissingPluginException {
      // Flutter web, or a desktop target without the plugin registered.
      return BiometricAvailability.unsupported;
    }
  }

  /// The sensor to advertise.
  ///
  /// Face wins when a device offers both, because that is the one the OS
  /// prompt will lead with.
  Future<BiometricKind> primaryKind() async {
    try {
      final List<BiometricType> types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      if (types.contains(BiometricType.iris)) return BiometricKind.iris;
      // `strong`/`weak` without a specific type: Android declining to say
      // which sensor it is. Fingerprint is the safe assumption there.
      if (types.isNotEmpty) return BiometricKind.fingerprint;
      return BiometricKind.none;
    } catch (_) {
      return BiometricKind.none;
    }
  }

  /// Runs the OS prompt.
  ///
  /// Returns true only on a genuine pass, and false when the user declines
  /// or simply fails the check — backing out is not an error and must not
  /// raise a red banner. Anything the user can act on is thrown as a
  /// [BiometricException] carrying a message written for them.
  ///
  /// [biometricOnly] stays false so the OS may fall back to the device
  /// passcode. A passcode still establishes "this person is holding the
  /// unlocked phone", which is the property the device secret depends on,
  /// and refusing it would strand anyone whose finger will not read on a
  /// cold Bloemfontein morning.
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        // Keeps the prompt alive if the user is interrupted by a call
        // mid-check rather than failing them out of it.
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'MoTiroong',
            signInHint: 'Confirm it is you to continue',
            cancelButton: 'Use password',
          ),
          IOSAuthMessages(
            cancelButton: 'Use password',
            localizedFallbackTitle: 'Enter passcode',
          ),
        ],
      );
    } on LocalAuthException catch (e) {
      // The user choosing to back out, or asking for the password instead,
      // is a normal outcome — report it as "did not authenticate".
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled ||
          e.code == LocalAuthExceptionCode.userRequestedFallback ||
          e.code == LocalAuthExceptionCode.timeout) {
        return false;
      }
      throw BiometricException(
        _messageFor(e.code),
        availability: _availabilityFor(e.code),
      );
    } on MissingPluginException {
      throw const BiometricException(
        'Biometric sign-in is not available on this platform.',
        availability: BiometricAvailability.unsupported,
      );
    }
  }

  /// Maps a failure code to something an employee can actually act on.
  ///
  /// The enum is explicitly documented as open to new values, so this must
  /// keep its fallback rather than being an exhaustive switch.
  static String _messageFor(LocalAuthExceptionCode code) => switch (code) {
    LocalAuthExceptionCode.noBiometricHardware =>
      'This device does not have a fingerprint or face sensor.',
    LocalAuthExceptionCode.noBiometricsEnrolled =>
      'No fingerprint or face is set up on this device yet. Add one in your device Settings, then try again.',
    LocalAuthExceptionCode.noCredentialsSet =>
      'Set a screen lock on this device before turning on biometric sign-in.',
    LocalAuthExceptionCode.temporaryLockout =>
      'Too many attempts. Wait a moment, then try again.',
    LocalAuthExceptionCode.biometricLockout =>
      'Biometric sign-in is locked. Unlock your device with your passcode to re-enable it.',
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
      'The sensor is busy right now. Please try again in a moment.',
    LocalAuthExceptionCode.authInProgress =>
      'A sign-in check is already running.',
    _ => 'Biometric check could not be completed. Please use your password.',
  };

  static BiometricAvailability? _availabilityFor(LocalAuthExceptionCode code) =>
      switch (code) {
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAvailability.notEnrolled,
        LocalAuthExceptionCode.noBiometricHardware =>
          BiometricAvailability.unsupported,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAvailability.lockedOut,
        _ => null,
      };
}
