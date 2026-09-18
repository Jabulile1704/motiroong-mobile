import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_exception.dart';

/// The single door onto the backend's callable Cloud Functions.
///
/// There is no REST client here and no bearer header to manage: the Firebase
/// SDK attaches the caller's ID token to every callable and refreshes it when
/// it expires. That is why `ApiEndpoints` and `auth_interceptor.dart` no
/// longer exist — there is nothing left for them to do.
///
/// The region is not optional. Every function in `motiroong-backend` is
/// deployed to `africa-south1` (see `functions/src/config.ts`), and a client
/// that forgets to say so will quietly call `us-central1` and get a 404 that
/// looks exactly like a missing function.
class FunctionsClient {
  const FunctionsClient();

  /// Johannesburg. Must match `Config.region` in the backend.
  static const String region = 'africa-south1';

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: region);

  /// Points the client at a locally running emulator suite.
  ///
  /// Call once from `main()` when `--dart-define=USE_EMULATORS=true`. On a
  /// physical phone `host` must be your machine's LAN address, not
  /// `localhost` — the phone's localhost is the phone.
  static void useEmulators({String host = 'localhost'}) {
    _functions.useFunctionsEmulator(host, 5001);
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
  }

  /// Calls [name] and returns its payload as a map.
  ///
  /// Every backend callable returns a JSON object, so the cast is safe; a
  /// response that is not a map means the function threw in a way the SDK
  /// could not classify, and that surfaces as an [AppException] rather than
  /// a `_TypeError` three frames away from the cause.
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic>? payload,
  ]) async {
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable(name)
          .call<dynamic>(payload ?? const <String, dynamic>{});

      final dynamic data = result.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{'value': data};
    } on FirebaseFunctionsException catch (e) {
      throw AppException(_messageFor(e), code: e.code, cause: e);
    } on FirebaseAuthException catch (e) {
      throw AppException(
        e.message ?? 'Your session has expired. Please sign in again.',
        code: e.code,
        cause: e,
      );
    }
  }

  /// The backend writes user-facing text into `HttpsError`'s message on every
  /// deliberate failure, so prefer it. The fallbacks below only cover the
  /// cases the SDK raises on its own — no network, a cold start that ran long,
  /// a token that expired mid-flight.
  static String _messageFor(FirebaseFunctionsException e) {
    final String? message = e.message?.trim();
    if (message != null && message.isNotEmpty && message != 'INTERNAL') {
      return message;
    }
    return switch (e.code) {
      'unavailable' =>
        'Cannot reach MoTiroong right now. Check your connection and try again.',
      'deadline-exceeded' => 'That took too long. Please try again.',
      'unauthenticated' => 'Please sign in again to continue.',
      'permission-denied' =>
        'You do not have permission to do that.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
