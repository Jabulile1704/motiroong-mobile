/// Form field validators. Return `null` when valid, or an error message.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _employeeId = RegExp(r'^[A-Za-z0-9-]{3,}$');

  /// Accepts either a work email address or an employee ID (e.g. EMP-0042).
  static String? identifier(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email or employee ID';
    if (_email.hasMatch(v) || _employeeId.hasMatch(v)) return null;
    return 'Enter a valid email or employee ID';
  }

  static String? password(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (v.length < 4) return 'Password must be at least 4 characters';
    return null;
  }
}
