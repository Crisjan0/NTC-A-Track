import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AuthException implements Exception {
  final String message;

  /// Whether this failure should count toward the login rate-limit lock.
  /// Only wrong passwords count — unknown accounts, network errors and
  /// stale sessions do not.
  final bool countTowardLock;

  const AuthException(this.message, {this.countTowardLock = false});

  @override
  String toString() => message;
}

/// Bridge between the app's accounts (usernames / student IDs) and
/// Firebase Authentication.
///
/// Design (client-only, no backend):
/// - Every admin / student owns exactly one Firebase Auth user whose email
///   is synthetic and versioned, e.g. `a_jdoe.v1@ntc-atrack.local`.
///   The email is derived from the Firestore document ID (immutable), so
///   renames never break the mapping; password resets bump the version.
/// - The public `authdir` collection maps a login identifier to its current
///   Auth email: doc `a_jdoe` / `s_2026_0001` -> { email, uid, version }.
///   It contains NO secrets, so pre-login reads are safe. Writes require
///   a signed-in user (except first-run seeding, which happens while the
///   rules are still in their temporary open state).
/// - Account provisioning (seed / add / import / reset) uses a SECONDARY
///   FirebaseApp, so creating Auth users never disturbs the admin's own
///   session on the primary app.
///
/// Known limitation (documented): deleting/replacing an Auth account leaves
/// the old Auth user orphaned (the client SDK cannot delete other users).
/// Logins reconcile `uid` against `authdir`, so orphans are rejected by the
/// app. Fully invalidating them needs the Admin SDK (future backend).
class AuthLink {
  AuthLink._();

  static const String authdirCollection = 'authdir';

  /// Per-user role records keyed by Firebase Auth uid: { kind, updated_at }.
  /// Firestore rules check these, so access is tied to a provisioned
  /// account — NOT to merely having *some* Auth session. Self-signed-up
  /// accounts have no role doc and are denied everywhere.
  static const String rolesCollection = 'roles';
  static const String emailDomain = 'ntc-atrack.local';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // ------------------------------------------------------------ identifiers

  /// Lowercase slug safe for doc IDs and email local parts.
  static String slug(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  static String adminKey(String username) => 'a_${slug(username)}';
  static String studentKey(String studentId) => 's_${slug(studentId)}';

  static String _emailFor({
    required bool isAdmin,
    required String docId,
    required int version,
  }) {
    final prefix = isAdmin ? 'a' : 's';
    return '${prefix}_$docId.v$version@$emailDomain';
  }

  // ----------------------------------------------------------- secondary app

  static FirebaseApp? _secondaryApp;

  /// Auth instance on an isolated app, so provisioning never signs the
  /// current admin out of the primary session.
  static Future<FirebaseAuth> _provisionAuth() async {
    _secondaryApp ??= await Firebase.initializeApp(
      name: 'provision',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirebaseAuth.instanceFor(app: _secondaryApp!);
  }

  // ---------------------------------------------------------------- authdir

  static Future<Map<String, dynamic>?> readEntry(String key) async {
    final doc = await _db.collection(authdirCollection).doc(key).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  static Future<Map<String, dynamic>?> readAdmin(String username) =>
      readEntry(adminKey(username));

  static Future<Map<String, dynamic>?> readStudent(String studentId) =>
      readEntry(studentKey(studentId));

  // ------------------------------------------------------------ provisioning

  /// Creates (or re-creates, version-bumped) the Firebase Auth user for an
  /// admin. Safe to retry: a missing entry starts at v1, an existing one
  /// bumps the version so stale sessions stop working.
  static Future<String> provisionAdmin({
    required String username,
    required String password,
    required String docId,
  }) async {
    return _provision(
      key: adminKey(username),
      ref: username.trim(),
      isAdmin: true,
      docId: docId,
      password: password,
    );
  }

  /// Creates (or re-creates, version-bumped) the Firebase Auth user for a
  /// student.
  static Future<String> provisionStudent({
    required String studentId,
    required String password,
    required String docId,
  }) async {
    return _provision(
      key: studentKey(studentId),
      ref: studentId.trim(),
      isAdmin: false,
      docId: docId,
      password: password,
    );
  }

  static Future<String> _provision({
    required String key,
    required String ref,
    required bool isAdmin,
    required String docId,
    required String password,
  }) async {
    final existing = await readEntry(key);
    final version = ((existing?['version'] as num?) ?? 0).toInt() + 1;
    final email = _emailFor(isAdmin: isAdmin, docId: docId, version: version);

    final provisionAuth = await _provisionAuth();
    UserCredential cred;
    try {
      cred = await provisionAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyProvisionError(e));
    }
    final uid = cred.user?.uid ?? '';
    // Creating a user signs the SECONDARY app in as that user — sign it
    // back out so the next provisioning starts clean.
    await provisionAuth.signOut();

    await _db.collection(authdirCollection).doc(key).set({
      'email': email,
      'uid': uid,
      'kind': isAdmin ? 'admin' : 'student',
      'ref': ref,
      'version': version,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await writeRole(uid: uid, kind: isAdmin ? 'admin' : 'student');
    return email;
  }

  /// Admin password reset (or student password change by admin): bumps the
  /// version and provisions a fresh Auth user. The old Auth account becomes
  /// an orphan: its role doc is deleted, so it is rejected everywhere
  /// (app login AND direct API reads) by the rules.
  static Future<void> resetAdminPassword({
    required String username,
    required String docId,
    required String newPassword,
  }) async {
    await _reset(
      key: adminKey(username),
      ref: username.trim(),
      isAdmin: true,
      docId: docId,
      newPassword: newPassword,
    );
  }

  static Future<void> resetStudentPassword({
    required String studentId,
    required String docId,
    required String newPassword,
  }) async {
    await _reset(
      key: studentKey(studentId),
      ref: studentId.trim(),
      isAdmin: false,
      docId: docId,
      newPassword: newPassword,
    );
  }

  static Future<void> _reset({
    required String key,
    required String ref,
    required bool isAdmin,
    required String docId,
    required String newPassword,
  }) async {
    final oldEntry = await readEntry(key);
    final oldUid = oldEntry?['uid'] as String?;
    await _provision(
      key: key,
      ref: ref,
      isAdmin: isAdmin,
      docId: docId,
      password: newPassword,
    );
    // Kill the orphan: without its role doc the old session passes no rule.
    if (oldUid != null && oldUid.isNotEmpty) {
      await deleteRole(oldUid);
    }
  }

  /// Moves an authdir entry when a username / student ID is renamed.
  /// The Auth account itself is untouched (email is docId-based).
  static Future<void> moveKey({
    required String oldKey,
    required String newKey,
    required String newRef,
  }) async {
    if (oldKey == newKey) return;
    final existing = await readEntry(oldKey);
    if (existing == null) return;
    final updated = Map<String, dynamic>.from(existing)..['ref'] = newRef;
    await _db.collection(authdirCollection).doc(newKey).set(updated);
    await _db.collection(authdirCollection).doc(oldKey).delete();
  }

  static Future<void> moveAdminKey({
    required String oldUsername,
    required String newUsername,
  }) =>
      moveKey(
        oldKey: adminKey(oldUsername),
        newKey: adminKey(newUsername),
        newRef: newUsername.trim(),
      );

  static Future<void> moveStudentKey({
    required String oldStudentId,
    required String newStudentId,
  }) =>
      moveKey(
        oldKey: studentKey(oldStudentId),
        newKey: studentKey(newStudentId),
        newRef: newStudentId.trim(),
      );

  /// Removes the login mapping AND the role doc when an account is
  /// deleted (best effort). Without its role doc, any lingering Auth
  /// session for the account passes no Firestore rule.
  static Future<void> removeLogin(String key) async {
    try {
      final entry = await readEntry(key);
      final uid = entry?['uid'] as String?;
      await _db.collection(authdirCollection).doc(key).delete();
      if (uid != null && uid.isNotEmpty) {
        await deleteRole(uid);
      }
    } catch (_) {
      // Entry may not exist (e.g. provisioning never completed).
    }
  }

  static Future<void> removeAdminLogin(String username) =>
      removeLogin(adminKey(username));

  static Future<void> removeStudentLogin(String studentId) =>
      removeLogin(studentKey(studentId));

  // ------------------------------------------------------------------- roles

  /// Grants data access to a Firebase Auth uid. Callable during first-run
  /// seeding (open-rules window) and by signed-in admins afterwards.
  static Future<void> writeRole({
    required String uid,
    required String kind,
  }) async {
    if (uid.isEmpty) return;
    await _db.collection(rolesCollection).doc(uid).set({
      'kind': kind,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Revokes data access for a Firebase Auth uid (best effort).
  static Future<void> deleteRole(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection(rolesCollection).doc(uid).delete();
    } catch (_) {
      // May not exist or rules may deny — login checks handle the rest.
    }
  }

  /// Returns the provisioned role ('admin' | 'student') for [uid], or null
  /// when the account was never provisioned (e.g. self-signed-up).
  static Future<String?> readRole(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _db.collection(rolesCollection).doc(uid).get();
      if (!doc.exists) return null;
      return doc.data()?['kind'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------ login

  /// Signs in on the PRIMARY app and returns the Firebase user.
  /// Throws [AuthException] with a user-friendly message on failure.
  /// Wrong passwords are marked with [AuthException.countTowardLock] so
  /// callers only count those toward the rate-limit lock.
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthException('Login failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _friendlySignInError(e),
        countTowardLock: _isWrongPassword(e),
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Signing out is best effort (e.g. never signed in).
    }
  }

  // ---------------------------------------------------------------- messages

  static String _friendlySignInError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'Account not found. Please check your username or Student ID.';
      case 'user-disabled':
        return 'This account has been disabled. Contact an admin.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and try again.';
      default:
        return 'Login failed (${e.code}). Please try again.';
    }
  }

  static bool _isWrongPassword(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return true;
      default:
        return false;
    }
  }

  static String _friendlyProvisionError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Login record already exists. Try again.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and try again.';
      default:
        return 'Could not create login (${e.code}). Check connection and try again.';
    }
  }
}
