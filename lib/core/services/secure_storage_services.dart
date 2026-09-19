import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed storage for the values that must never sit in plain text.
///
/// Chiefly the **device secret**: 32 random bytes that stand in for the
/// user's password once biometric sign-in is switched on. The backend holds
/// only its SHA-256, so this copy is the only one in existence — losing it
/// means re-enrolling, and leaking it would be equivalent to leaking a
/// password.
///
/// It is therefore stored behind the platform keystore rather than
/// `shared_preferences`, which is a plain XML file on Android and a plain
/// plist on iOS:
///
///   - **iOS/macOS** — Keychain, `first_unlock_this_device`. The
///     `_this_device` suffix is the important half: it keeps the secret out
///     of iCloud Keychain and out of device backups, so a restored phone
///     does not inherit the binding. That is the whole point — the secret is
///     supposed to identify *this* handset.
///   - **Android** — AES-GCM under an RSA-OAEP key in the hardware keystore.
///
/// A stricter option exists and was considered: `AccessControlFlag
/// .biometryCurrentSet` on iOS (and `enforceBiometrics` on Android) makes
/// the *keystore itself* refuse to release the secret without a biometric,
/// and invalidates it outright if someone later adds a fingerprint to the
/// device. That is genuinely stronger. It is not used here because it moves
/// the prompt inside every read, where the failure modes differ per platform
/// and cannot be presented to the user coherently. Instead [BiometricService]
/// runs one explicit gate before the read, which is easier to reason about
/// and to show sensible errors for. Worth revisiting if the threat model
/// tightens.
class SecureStorageService {
  const SecureStorageService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    // The v11 defaults are already the strong ones — AES-GCM data encryption
    // under an RSA-OAEP key held in the Android keystore — so there is
    // nothing to harden here. `resetOnError` drops the entry rather than
    // throwing if the keystore entry is ever corrupted (an OS upgrade, a
    // restored backup); the user re-enrols, which beats a crash loop they
    // cannot escape.
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys are namespaced so a future feature cannot collide with them.
  static const String _kDeviceSecret = 'moti.device.secret';
  static const String _kDeviceId = 'moti.device.id';
  static const String _kEmployeeId = 'moti.biometric.employeeId';
  static const String _kDisplayName = 'moti.biometric.displayName';
  static const String _kMethod = 'moti.signin.method';
  static const String _kRegistered = 'moti.device.registered';

  // ---------------------------------------------------------------- secret

  /// The device secret, or null when biometric sign-in is not set up.
  Future<String?> readDeviceSecret() => _storage.read(key: _kDeviceSecret);

  Future<void> writeDeviceSecret(String secret) =>
      _storage.write(key: _kDeviceSecret, value: secret);

  // ------------------------------------------------------------- device id

  /// A stable id for this installation.
  ///
  /// Deliberately *not* the hardware identifier (IMEI, `identifierForVendor`,
  /// Android ID). Those are either unavailable, resettable, or privacy-
  /// sensitive, and none of them are needed: the id only has to distinguish
  /// this install from the user's other devices, and it is meaningless
  /// without the secret stored alongside it.
  Future<String> deviceId() async {
    final String? existing = await _storage.read(key: _kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    final String generated = _randomHex(16);
    await _storage.write(key: _kDeviceId, value: generated);
    return generated;
  }

  // ------------------------------------------------------- registration

  /// Set once anyone has registered or signed in on this phone, so the app
  /// opens on sign-in rather than sign-up from then on. On iOS the Keychain
  /// keeps it across a reinstall, which is the behaviour we want: the phone
  /// has an account behind it.
  Future<void> markRegistered() =>
      _storage.write(key: _kRegistered, value: 'true');

  Future<bool> isRegistered() async =>
      await _storage.read(key: _kRegistered) == 'true';

  // ------------------------------------------------------ enrolment record

  /// Remembers who this device is enrolled for.
  ///
  /// `signInWithDevice` needs the staff number, and the login screen needs a
  /// name to greet. Neither is secret — on its own the staff number gets an
  /// attacker nothing — but keeping them here means one read unlocks the
  /// whole biometric path.
  Future<void> writeEnrollment({
    required String employeeId,
    required String displayName,
    required String method,
  }) async {
    await _storage.write(key: _kEmployeeId, value: employeeId);
    await _storage.write(key: _kDisplayName, value: displayName);
    await _storage.write(key: _kMethod, value: method);
  }

  /// `biometric` or `pin`. Enrolments from before PIN support have no value
  /// and were biometric.
  Future<String> readEnrolledMethod() async =>
      await _storage.read(key: _kMethod) ?? 'biometric';

  Future<String?> readEnrolledEmployeeId() => _storage.read(key: _kEmployeeId);

  Future<String?> readEnrolledDisplayName() =>
      _storage.read(key: _kDisplayName);

  /// True when this device has a secret and knows who it belongs to.
  Future<bool> hasBiometricEnrollment() async {
    final String? secret = await readDeviceSecret();
    final String? employeeId = await readEnrolledEmployeeId();
    return secret != null &&
        secret.isNotEmpty &&
        employeeId != null &&
        employeeId.isNotEmpty;
  }

  /// Forgets the biometric enrolment, keeping the device id.
  ///
  /// Called when the user turns biometrics off, when the backend rejects the
  /// secret as unknown, or on a sign-out that revokes the device. The id
  /// survives so that re-enrolling reuses the same slot on the server rather
  /// than consuming another of the user's three.
  Future<void> clearBiometricEnrollment() async {
    await _storage.delete(key: _kDeviceSecret);
    await _storage.delete(key: _kEmployeeId);
    await _storage.delete(key: _kDisplayName);
    await _storage.delete(key: _kMethod);
  }

  /// Wipes everything, including the device id.
  Future<void> clearAll() async {
    await clearBiometricEnrollment();
    await _storage.delete(key: _kDeviceId);
  }

  // ---------------------------------------------------------------- helpers

  /// Generates [bytes] of cryptographic randomness as lowercase hex.
  ///
  /// [Random.secure] is the platform CSPRNG. The plain [Random] constructor
  /// would be seeded predictably and is not safe for this.
  static String _randomHex(int bytes) {
    final Random rng = Random.secure();
    final List<int> values = List<int>.generate(bytes, (_) => rng.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// A fresh 32-byte device secret, hex-encoded — what the backend expects.
  static String generateDeviceSecret() => _randomHex(32);

  /// Exposed for the enrolment screen's "your secret never leaves" copy.
  static String fingerprintOf(String secret) =>
      base64Url.encode(utf8.encode(secret)).substring(0, 8).toUpperCase();
}
