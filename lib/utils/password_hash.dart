import 'package:crypto/crypto.dart';

/// Password hashing utilities using salted SHA-256.
class PasswordHash {
  /// Returns a random salt + SHA-256 hash of salt+password.
  static Map<String, String> hash(
    String password, {
    String? salt,
  }) {
    final effectiveSalt = salt ?? _randomSalt();
    final hash = sha256.convert('$effectiveSalt:$password'.codeUnits);
    return {'salt': effectiveSalt, 'hash': hash.toString()};
  }

  static String _randomSalt() {
    final random = DateTime.now().microsecondsSinceEpoch;
    return '$random-${sha256.convert('$random'.codeUnits)}'
        .substring(0, 16);
  }

  /// Verifies a plain-text password against a stored hash + salt.
  static bool verify(String password, String salt, String hash) {
    final candidate = sha256.convert('$salt:$password'.codeUnits).toString();
    return candidate == hash;
  }
}