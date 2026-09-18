/// Where an employee sits in the approval workflow.
///
/// Mirrors `EmployeeStatus` in `motiroong-backend/functions/src/types.ts`.
/// This is the single most important field in the session: everything except
/// [EmployeeStatus.active] means the app shows a status screen instead of the
/// clock.
enum EmployeeStatus {
  pending,
  active,
  suspended,
  rejected;

  static EmployeeStatus parse(String? value) => switch (value) {
    'active' => EmployeeStatus.active,
    'suspended' => EmployeeStatus.suspended,
    'rejected' => EmployeeStatus.rejected,
    _ => EmployeeStatus.pending,
  };

  bool get canClock => this == EmployeeStatus.active;

  String get label => switch (this) {
    EmployeeStatus.pending => 'Awaiting approval',
    EmployeeStatus.active => 'Active',
    EmployeeStatus.suspended => 'Suspended',
    EmployeeStatus.rejected => 'Not approved',
  };
}

/// The signed-in employee, as `getMyProfile` returns them.
///
/// Note what is *not* here: no access token and no refresh token. The Firebase
/// SDK owns the ID token, attaches it to every callable and refreshes it on
/// its own, so there is nothing for the app to store or rotate.
///
/// [role] and [status] are also carried in the user's custom claims, which is
/// what `firestore.rules` reads. The copy here is for the UI only — a user who
/// tampered with it would change what their own screen says and nothing else.
class AuthResponse {
  const AuthResponse({
    required this.uid,
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.statusReason,
    this.siteId,
    this.department,
    this.biometricEnrolled = false,
    this.deviceCount = 0,
  });

  final String uid;

  /// Staff number, e.g. `EMP-0042`. The link to payroll.
  final String employeeId;
  final String fullName;
  final String email;

  /// `employee` | `supervisor` | `admin`.
  final String role;
  final EmployeeStatus status;

  /// Why an account was rejected or suspended, so the app can explain itself
  /// rather than showing a dead end.
  final String? statusReason;
  final String? siteId;
  final String? department;

  /// True when at least one device is bound for biometric sign-in — used to
  /// decide between "Turn on Face ID" and the biometric sign-in button.
  final bool biometricEnrolled;
  final int deviceCount;

  /// `JM` for "Jabulile Mashibini" — used for the avatar.
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

  /// `Supervisor` rather than `supervisor`, for display.
  String get roleLabel =>
      role.isEmpty ? 'Employee' : role[0].toUpperCase() + role.substring(1);

  bool get isAdmin => role == 'admin';
  bool get isReviewer => role == 'admin' || role == 'supervisor';

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    uid: json['uid'] as String? ?? '',
    employeeId: json['employeeId'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'employee',
    status: EmployeeStatus.parse(json['status'] as String?),
    statusReason: json['statusReason'] as String?,
    siteId: json['siteId'] as String?,
    department: json['department'] as String?,
    biometricEnrolled: json['biometricEnrolled'] as bool? ?? false,
    deviceCount: (json['deviceCount'] as num?)?.toInt() ?? 0,
  );

  AuthResponse copyWith({bool? biometricEnrolled, int? deviceCount}) =>
      AuthResponse(
        uid: uid,
        employeeId: employeeId,
        fullName: fullName,
        email: email,
        role: role,
        status: status,
        statusReason: statusReason,
        siteId: siteId,
        department: department,
        biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
        deviceCount: deviceCount ?? this.deviceCount,
      );
}
