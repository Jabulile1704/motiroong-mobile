import 'package:flutter/foundation.dart';

import '../../../../core/services/location_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_response.dart';
import '../../domain/auth_state.dart';

/// App-wide auth state. Listen with [ListenableBuilder]; the root widget
/// switches between LoginScreen and AppScaffold based on [state].
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

  /// Geo-tagged sign-in: the captured [location] is sent with the
  /// credentials so the server can record where the session started.
  Future<void> signIn({
    required String identifier,
    required String password,
    required LocationResult location,
  }) async {
    _state = const AuthSigningIn();
    notifyListeners();
    try {
      final AuthResponse session = await _repository.signIn(
        identifier: identifier,
        password: password,
        location: location,
      );
      _state = AuthSignedIn(session);
    } on AuthException catch (e) {
      _state = AuthFailure(e.message);
    } catch (_) {
      _state = const AuthFailure(
        'Could not sign in. Check your connection and try again.',
      );
    }
    notifyListeners();
  }

  void signOut() {
    _state = const AuthSignedOut();
    notifyListeners();
  }
}

/// Single app-wide instance.
final AuthProvider authProvider = AuthProvider();
