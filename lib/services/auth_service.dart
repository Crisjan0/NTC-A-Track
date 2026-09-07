import '../models/student_model.dart';
import '../models/user_model.dart';
import 'database_service_factory.dart';
import 'database_service_interface.dart';
import 'login_rate_limiter.dart';
import 'session_service.dart';

/// Handles authentication for both roles.
///
/// Admin logs in with a username; students log in with their Student ID.
/// Passwords are stored as salted SHA-256 hashes (local demo equivalent of
/// backend password hashing) and are never kept in plain text.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final DatabaseServiceInterface _db = DatabaseServiceFactory.instance;
  final SessionService _sessions = SessionService.instance;

  /// Returns the created session, or throws [AuthException] / [RateLimitException]
  /// on failure.
  Future<Session> loginAdmin(String username, String password) async {
    final identifier = username.trim();
    await _enforceRateLimit(identifier);

    final user = await _db.getUserByUsername(identifier);
    if (user == null) {
      throw const AuthException('Account not found. Please check your username.');
    }
    if (!DatabaseServiceInterface.verifyPassword(password, user.salt, user.passwordHash)) {
      await _recordFailureOrThrow(identifier);
      throw const AuthException('Incorrect password. Please try again.');
    }
    await LoginRateLimiter.instance.clear(identifier);

    final session = Session(role: 'admin', username: user.username);
    await _sessions.save(session);
    return session;
  }

  /// Students log in with their Student ID number.
  Future<Session> loginStudent(String studentId, String password) async {
    final identifier = studentId.trim();
    await _enforceRateLimit(identifier);

    final student = await _db.getStudentById(identifier);
    if (student == null) {
      throw const AuthException('Student not found. Please check your Student ID.');
    }
    if (!DatabaseServiceInterface.verifyPassword(
        password, student.salt, student.passwordHash)) {
      await _recordFailureOrThrow(identifier);
      throw const AuthException('Incorrect password. Please try again.');
    }
    await LoginRateLimiter.instance.clear(identifier);

    final session = Session(
      role: 'student',
      username: student.studentId,
      studentId: student.studentId,
      fullName: student.fullName,
    );
    await _sessions.save(session);
    return session;
  }

  /// Unified auto-detecting login - tries to authenticate as either admin or
  /// student based on the provided identifier. Returns the session and the
  /// detected role. Wrong passwords count toward the per-identifier lock.
  Future<Session> loginAuto(String identifier, String password) async {
    final cleaned = identifier.trim();
    await _enforceRateLimit(cleaned);

    // Try as admin first (username).
    final user = await _db.getUserByUsername(cleaned);
    if (user != null) {
      if (DatabaseServiceInterface.verifyPassword(
          password, user.salt, user.passwordHash)) {
        await LoginRateLimiter.instance.clear(cleaned);
        final session = Session(role: 'admin', username: user.username);
        await _sessions.save(session);
        return session;
      }
      await _recordFailureOrThrow(cleaned);
      throw const AuthException('Incorrect password. Please try again.');
    }

    // Try as student (Student ID).
    final student = await _db.getStudentById(cleaned);
    if (student != null) {
      if (DatabaseServiceInterface.verifyPassword(
          password, student.salt, student.passwordHash)) {
        await LoginRateLimiter.instance.clear(cleaned);
        final session = Session(
          role: 'student',
          username: student.studentId,
          studentId: student.studentId,
          fullName: student.fullName,
        );
        await _sessions.save(session);
        return session;
      }
      await _recordFailureOrThrow(cleaned);
      throw const AuthException('Incorrect password. Please try again.');
    }

    // Neither admin nor student found.
    throw const AuthException(
      'Account not found. Please check your username or Student ID.',
    );
  }

  /// Throws [RateLimitException] if [identifier] is currently locked.
  Future<void> _enforceRateLimit(String identifier) async {
    final remaining = await LoginRateLimiter.instance
        .remainingLockSeconds(identifier);
    if (remaining > 0) throw RateLimitException(remaining);
  }

  /// Records a failed password attempt; throws [RateLimitException] when the
  /// attempt triggers the lock.
  Future<void> _recordFailureOrThrow(String identifier) async {
    final remaining = await LoginRateLimiter.instance
        .recordFailure(identifier);
    if (remaining > 0) throw RateLimitException(remaining);
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