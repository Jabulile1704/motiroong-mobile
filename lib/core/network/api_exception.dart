/// Errors raised by the backend layer, already phrased for a user.
///
/// Every `FirebaseFunctionsException` and `FirebaseAuthException` is funnelled
/// through [AppException] by `functions_client.dart` so that no screen ever
/// has to know which SDK a failure came from — or accidentally show a user a
/// string like `[firebase_functions/failed-precondition]`.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  /// Safe to show in the UI as-is.
  final String message;

  /// The backend's error code (`permission-denied`, `failed-precondition`, …).
  /// Screens branch on this rather than matching on [message].
  final String? code;

  /// The original exception, kept for logging. Never shown to the user.
  final Object? cause;

  /// The caller is signed in but their account is not `active` yet — the
  /// pending-approval screen, not an error banner.
  bool get isPendingApproval => code == 'failed-precondition';

  /// The caller has no valid session; send them back to the login screen.
  bool get isUnauthenticated => code == 'unauthenticated';

  /// No network, or the request timed out. Worth offering a retry.
  bool get isOffline => code == 'unavailable' || code == 'deadline-exceeded';

  @override
  String toString() => message;
}
