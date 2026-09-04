import '../models/student_model.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'session_service.dart';

/// Handles authentication for both roles.
///
/// Admin logs in with a username; students log in with their Student ID.
/// Passwords are stored as salted SHA-256 hashes (local demo equivalent of
/// backend password hashing) and are never kept in plain text.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final DatabaseService _db = DatabaseService.instance;
  final SessionService _sessions = SessionService.instance;

  /// Returns the created session, or throws [AuthException] on failure.
  Future<Session> loginAdmin(String username, String password) async {
    final user = await _db.getUserByUsername(username);
    if (user == null) {
      throw const AuthException('Account not found. Please check your username.');
    }
    _verify(user.passwordHash, user.salt, password);

    final session = Session(role: 'admin', username: user.username);
    await _sessions.save(session);
    return session;
  }

  /// Students log in with their Student ID number.
  Future<Session> loginStudent(String studentId, String password) async {
    final student = await _db.getStudentById(studentId.trim());
    if (student == null) {
      throw const AuthException('Student not found. Please check your Student ID.');
    }
    _verify(student.passwordHash, student.salt, password);

    final session = Session(
      role: 'student',
      username: student.studentId,
      studentId: student.studentId,
      fullName: student.fullName,
    );
    await _sessions.save(session);
    return session;
  }

  void _verify(String storedHash, String salt, String password) {
    if (!DatabaseService.verifyPassword(password, salt, storedHash)) {
      throw const AuthException('Incorrect password. Please try again.');
    }
  }

  Future<void> logout() => _sessions.clear();

  /// Re-fetches the student record behind the current student session
  /// (keeps displayed data fresh after edits).
  Future<Student?> currentStudent() async {
    final session = _sessions.current;
    if (session == null || !session.isStudent || session.studentId == null) {
      return null;
    }
    return _db.getStudentById(session.studentId!);
  }

  Future<User?> currentAdmin() async {
    final session = _sessions.current;
    if (session == null || !session.isAdmin) return null;
    return _db.getUserByUsername(session.username);
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}