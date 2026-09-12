import '../models/student_model.dart';
import '../models/user_model.dart';
import 'auth_link.dart';
import 'database_service_factory.dart';
import 'database_service_interface.dart';
import 'login_rate_limiter.dart';
import 'session_service.dart';

/// Handles authentication for both roles.
///
/// Login is gated by Firebase Authentication: the app looks up the account's
/// Auth email in the public `authdir` collection, signs in, then loads the
/// Firestore profile. Firestore rules therefore only serve signed-in users.
///
/// Admin logs in with a username; students log in with their Student ID.
/// Passwords live in Firebase Auth (never in Firestore).
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

    final entry = await AuthLink.readAdmin(identifier);
    if (entry == null) {
      throw const AuthException('Account not found. Please check your username.');
    }
    final email = entry['email'] as String?;

    try {
      if (email == null || email.isEmpty) throw const AuthException('Account not found. Please check your username.');
      final firebaseUser = await AuthLink.signIn(email: email, password: password);
      await _checkUid(firebaseUser.uid, entry);
      await _checkRole(firebaseUser.uid);
    } on AuthException catch (e) {
      if (e.countTowardLock) await _recordFailureOrThrow(identifier);
      rethrow;
    }
    await LoginRateLimiter.instance.clear(identifier);

    final user = await _db.getUserByUsername(identifier);
    final session = Session(role: 'admin', username: user?.username ?? identifier);
    await _sessions.save(session);
    return session;
  }

  /// Students log in with their Student ID number.
  Future<Session> loginStudent(String studentId, String password) async {
    final identifier = studentId.trim();
    await _enforceRateLimit(identifier);

    final entry = await AuthLink.readStudent(identifier);
    if (entry == null) {
      throw const AuthException('Student not found. Please check your Student ID.');
    }
    final email = entry['email'] as String?;

    try {
      if (email == null || email.isEmpty) throw const AuthException('Student not found. Please check your Student ID.');
      final firebaseUser = await AuthLink.signIn(email: email, password: password);
      await _checkUid(firebaseUser.uid, entry);
      await _checkRole(firebaseUser.uid);
    } on AuthException catch (e) {
      if (e.countTowardLock) await _recordFailureOrThrow(identifier);
      rethrow;
    }
    await LoginRateLimiter.instance.clear(identifier);

    final student = await _db.getStudentById(identifier);
    final session = Session(
      role: 'student',
      username: student?.studentId ?? identifier,
      studentId: student?.studentId ?? identifier,
      fullName: student?.fullName,
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
    final adminEntry = await AuthLink.readAdmin(cleaned);
    if (adminEntry != null) {
      return _loginWithEntry(
        identifier: cleaned,
        entry: adminEntry,
        isAdmin: true,
        password: password,
      );
    }

    // Try as student (Student ID).
    final studentEntry = await AuthLink.readStudent(cleaned);
    if (studentEntry != null) {
      return _loginWithEntry(
        identifier: cleaned,
        entry: studentEntry,
        isAdmin: false,
        password: password,
      );
    }

    // Neither admin nor student found.
    throw const AuthException(
      'Account not found. Please check your username or Student ID.',
    );
  }

  Future<Session> _loginWithEntry({
    required String identifier,
    required Map<String, dynamic> entry,
    required bool isAdmin,
    required String password,
  }) async {
    final email = entry['email'] as String?;
    if (email == null || email.isEmpty) {
      throw const AuthException(
        'Account not found. Please check your username or Student ID.',
      );
    }
    try {
      final firebaseUser = await AuthLink.signIn(email: email, password: password);
      await _checkUid(firebaseUser.uid, entry);
      await _checkRole(firebaseUser.uid);
    } on AuthException catch (e) {
      if (e.countTowardLock) await _recordFailureOrThrow(identifier);
      rethrow;
    }
    await LoginRateLimiter.instance.clear(identifier);

    if (isAdmin) {
      final user = await _db.getUserByUsername(identifier);
      final session = Session(role: 'admin', username: user?.username ?? identifier);
      await _sessions.save(session);
      return session;
    }
    final student = await _db.getStudentById(identifier);
    final session = Session(
      role: 'student',
      username: student?.studentId ?? identifier,
      studentId: student?.studentId ?? identifier,
      fullName: student?.fullName,
    );
    await _sessions.save(session);
    return session;
  }

  /// Rejects stale sessions (e.g. orphaned Auth accounts left behind by a
  /// password reset). The recorded uid in `authdir` is the source of truth.
  Future<void> _checkUid(String uid, Map<String, dynamic> entry) async {
    final recorded = entry['uid'] as String?;
    if (recorded != null && recorded.isNotEmpty && recorded != uid) {
      await AuthLink.signOut();
      throw const AuthException(
        'This login is no longer valid. Please contact an admin.',
      );
    }
  }

  /// Rejects signed-in users that were never provisioned by an admin
  /// (e.g. self-signed-up accounts). Their uid has no role doc.
  Future<void> _checkRole(String uid) async {
    final role = await AuthLink.readRole(uid);
    if (role != 'admin' && role != 'student') {
      await AuthLink.signOut();
      throw const AuthException(
        'This account has no school access. Contact an admin.',
      );
    }
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

  Future<void> logout() async {
    await AuthLink.signOut();
    await _sessions.clear();
  }

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
