import '../../../core/services/location_service.dart';
import 'models/auth_response.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the auth backend.
///
/// Currently simulates the network call so the flow can be built and
/// tested end-to-end before the real API exists. Swap the body of
/// [signIn] for a POST to [ApiEndpoints.login] when the backend is ready
/// — the geo-tag is already part of the request payload.
class AuthRepository {
  const AuthRepository();

  Future<AuthResponse> signIn({
    required String identifier,
    required String password,
    required LocationResult location,
  }) async {
    // Simulated request. The real implementation will send:
    // { "identifier": ..., "password": ..., "location": location.toJson() }
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    // Demo failure path so the error UI can be exercised: use the
    // password "wrong" to see a rejected login.
    if (password.toLowerCase() == 'wrong') {
      throw const AuthException('Incorrect email/employee ID or password.');
    }

    final String name = identifier.contains('@')
        ? identifier.split('@').first.replaceAll('.', ' ')
        : 'Employee $identifier';

    return AuthResponse(
      token: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      employeeId: identifier.contains('@') ? 'EMP-0001' : identifier,
      fullName: _titleCase(name),
      role: 'Employee',
    );
  }

  static String _titleCase(String s) => s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
