/// REST endpoints for the MoTiroong backend.
///
/// `baseUrl` is a placeholder — point it at the real API when available.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.motirong.example.com/v1';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String enrollDevice = '$baseUrl/auth/devices';

  // Attendance
  static const String clockIn = '$baseUrl/attendance/clock-in';
  static const String clockOut = '$baseUrl/attendance/clock-out';
  static const String attendanceHistory = '$baseUrl/attendance/records';

  // Exception requests
  static const String exceptions = '$baseUrl/exceptions';
}
