/// Payload returned by a successful login.
class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.employeeId,
    required this.fullName,
    required this.role,
  });

  final String token;
  final String employeeId;
  final String fullName;
  final String role;

  /// `JM` for "Jabulile M." — used for the avatar.
  String get initials {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] as String,
    employeeId: json['employee_id'] as String,
    fullName: json['full_name'] as String,
    role: json['role'] as String? ?? 'Employee',
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'employee_id': employeeId,
    'full_name': fullName,
    'role': role,
  };
}
