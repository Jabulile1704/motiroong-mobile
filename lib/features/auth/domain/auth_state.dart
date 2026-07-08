import '../data/models/auth_response.dart';

/// The authentication states the app can be in.
sealed class AuthState {
  const AuthState();
}

/// No session — show the login screen.
class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// Credentials submitted, waiting for the server.
class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

/// Login succeeded — show the main app.
class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final AuthResponse session;
}

/// Login failed — show the login screen with an error.
class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}
