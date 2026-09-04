/// Simple input validators used across forms.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? username(String? value) => required(value, field: 'Username');

  static String? password(String? value) {
    final base = required(value, field: 'Password');
    if (base != null) return base;
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? studentId(String? value) {
    final base = required(value, field: 'Student ID');
    if (base != null) return base;
    final cleaned = value!.trim();
    if (!RegExp(r'^\d{4}-\d{4}$').hasMatch(cleaned) &&
        !RegExp(r'^\d{4,10}$').hasMatch(cleaned)) {
      return 'Use a valid format (e.g. 2026-0001)';
    }
    return null;
  }

  static String? name(String? value, {required String field}) =>
      required(value, field: field);

  static String? picker(String? value, {required String field}) =>
      required(value, field: field);
}