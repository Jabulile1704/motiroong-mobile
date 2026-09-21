import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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

  /// Base URL of a backend spoken to over plain HTTP rather than through the
  /// Functions SDK — the emulator, or a self-hosted deployment.
  static Uri? _httpBase;

  /// Whether [_httpBase] is a local emulator, which only changes the wording
  /// of the "cannot reach it" error.
  static bool _httpBaseIsEmulator = false;

  /// Points the client at a backend that serves the callables itself.
  ///
  /// Cloud Functions requires the Blaze plan, so the same handlers can be run
  /// on any Node host instead (see `functions/src/server.ts` in
  /// motiroong-backend). An `onCall` handler is an Express handler: it
  /// verifies the ID token and writes the same wire format, so [_callHttp]
  /// below needs no idea which one it is talking to.
  ///
  /// Set with `--dart-define=BACKEND_URL=https://your-host.example`. Auth
  /// still goes to the real Firebase project, which is free on Spark.
  static void useHttpBackend(Uri base) {
    // A base without a trailing slash would make resolve() replace the last
    // path segment rather than append the function name to it.
    _httpBase = base.path.endsWith('/')
        ? base
        : base.replace(path: '${base.path}/');
    _httpBaseIsEmulator = false;
  }

  /// Points the client at a locally running emulator suite.
  ///
  /// Call once from `main()` when `--dart-define=USE_EMULATORS=true`. On a
  /// physical phone `host` must be your machine's LAN address, not
  /// `localhost` — the phone's localhost is the phone.
  ///
  /// Callables then go over plain HTTP from Dart rather than through the
  /// SDK. The iOS SDK refuses to attach the user's token to HTTP unless the
  /// host is loopback ("Refusing to send Auth, FCM and AppCheck tokens over
  /// HTTP to non-loopback host"), and its only override exists in debug
  /// builds — which cannot be launched wirelessly. The emulator speaks the
  /// same callable protocol either way.
  static Future<void> useEmulators({String host = 'localhost'}) async {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    final String projectId = Firebase.app().options.projectId;
    useHttpBackend(Uri.parse('http://$host:5001/$projectId/$region/'));
    _httpBaseIsEmulator = true;
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
    final Uri? base = _httpBase;
    if (base != null) return _callHttp(base.resolve(name), payload);

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

  /// The callable protocol by hand: POST `{data}` with the caller's ID token,
  /// receive `{result}` or `{error: {message, status}}`.
  ///
  /// Used for the emulator and for a self-hosted backend, which are the same
  /// protocol over the same shape of URL.
  Future<Map<String, dynamic>> _callHttp(
    Uri url,
    Map<String, dynamic>? payload,
  ) async {
    final String? idToken = await FirebaseAuth.instance.currentUser
        ?.getIdToken();
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final HttpClientRequest request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      if (idToken != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      }
      request.write(jsonEncode(<String, dynamic>{'data': payload ?? {}}));
      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 70),
      );
      final String body = await response.transform(utf8.decoder).join();
      final dynamic json = body.isEmpty ? null : jsonDecode(body);

      if (json is Map && json['error'] is Map) {
        final Map<dynamic, dynamic> error = json['error'] as Map;
        final String code = (error['status'] as String? ?? 'INTERNAL')
            .toLowerCase()
            .replaceAll('_', '-');
        final String message = (error['message'] as String? ?? '').trim();
        throw AppException(
          message.isNotEmpty && message != 'INTERNAL'
              ? message
              : 'Something went wrong. Please try again.',
          code: code,
        );
      }
      final dynamic data = json is Map ? json['result'] : null;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{'value': data};
    } on SocketException catch (e) {
      throw AppException(
        _httpBaseIsEmulator
            ? 'Cannot reach the MoTiroong emulator at ${url.host}. Is it '
                  'running, and is this phone on the same Wi-Fi?'
            : 'Cannot reach the MoTiroong server at ${url.host}. Check your '
                  'connection and try again.',
        code: 'unavailable',
        cause: e,
      );
    } on TimeoutException catch (e) {
      throw AppException(
        'That took too long. Please try again.',
        code: 'deadline-exceeded',
        cause: e,
      );
    } finally {
      client.close();
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
      'permission-denied' => 'You do not have permission to do that.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
