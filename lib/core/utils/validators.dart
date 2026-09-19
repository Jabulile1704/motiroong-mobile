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

  static String? fullName(String? value) {
    final String v = value?.trim() ?? '';
    if (v.length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your work email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Matches the backend's `claimEmployeeId`: letters, digits and dashes.
  static String? optionalEmployeeId(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z0-9-]{3,32}$').hasMatch(v)) {
      return 'Letters, numbers and dashes only';
    }
    return null;
  }

  /// Mirrors the backend's `normalisePhone`: digits, spaces, dashes,
  /// brackets and a leading +, with 9 to 15 digits.
  static String? phone(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your phone number';
    if (!RegExp(r'^\+?[\d\s()-]+$').hasMatch(v)) {
      return 'Digits, spaces and dashes only';
    }
    final int digits = v.replaceAll(RegExp(r'\D'), '').length;
    if (digits < 9 || digits > 15)
      return 'Enter a full number, e.g. 082 555 1234';
    return null;
  }

  /// Firebase Auth and the backend both require 8 or more characters.
  static String? newPassword(String? value) {
    final String v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }
}
