import '../models/student_model.dart';
import '../utils/constants.dart';
import '../utils/year_level.dart';
import 'auth_link.dart';
import 'database_service_factory.dart';
import 'database_service_interface.dart';

/// One parsed student row from an import file (no password — imported
/// students always get [kDefaultStudentPassword]).
class StudentImportRow {
  final String studentId;
  final String firstName;
  final String lastName;
  final String course;
  final String yearLevel;

  const StudentImportRow({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.course,
    required this.yearLevel,
  });

  String get fullName => '$firstName $lastName';
}

/// Outcome of an import batch: how many were added and which rows were
/// skipped (duplicate IDs inside the file or already in the database).
class StudentImportResult {
  final int imported;
  final List<StudentImportRow> skipped;
  final List<String> skippedReasons;

  const StudentImportResult({
    required this.imported,
    required this.skipped,
    required this.skippedReasons,
  });

  int get skippedCount => skipped.length;
}

/// CRUD + search operations for students.
class StudentService {
  StudentService._();

  static final StudentService instance = StudentService._();

  final DatabaseServiceInterface _db = DatabaseServiceFactory.instance;

  Future<List<Student>> getAllStudents() => _db.getAllStudents();

  Future<Student?> getByStudentId(String studentId) =>
      _db.getStudentById(studentId);

  /// Adds a student; throws [StudentException] if the ID is already taken.
  /// Also provisions the Firebase Auth login for the student.
  Future<void> addStudent({
    required String studentId,
    required String lastName,
    required String firstName,
    required String course,
    required String yearLevel,
    required String password,
  }) async {
    final cleanedId = studentId.trim();
    if (await _db.studentIdExists(cleanedId)) {
      throw StudentException('Student ID "$cleanedId" is already in use.');
    }

    final docId = await _db.insertStudent(Student(
      studentId: cleanedId,
      lastName: lastName.trim(),
      firstName: firstName.trim(),
      course: course,
      yearLevel: yearLevel,
      passwordHash: kManagedByFirebaseAuth,
      salt: kManagedByFirebaseAuth,
      createdAt: DateTime.now(),
    ));
    try {
      await AuthLink.provisionStudent(
        studentId: cleanedId,
        password: password,
        docId: docId,
      );
    } catch (e) {
      // Firestore doc exists without a login — surface it so the admin
      // can retry (re-adding bumps the version and heals it).
      throw StudentException('Student saved but login setup failed: $e');
    }
  }

  /// Inserts a batch of imported students. Every row is given the shared
  /// default password [kDefaultStudentPassword] (and a Firebase Auth login);
  /// rows whose student ID is already in the database (or duplicated inside
  /// the same batch) are skipped and reported in the result.
  Future<StudentImportResult> importStudents(
    List<StudentImportRow> rows,
  ) async {
    var imported = 0;
    final skipped = <StudentImportRow>[];
    final skippedReasons = <String>[];
    final seen = <String>{}; // IDs already added earlier in this batch.

    for (final row in rows) {
      final id = row.studentId.trim();
      // Year Level is AUTO from the ID — empty CSV cell is fine when the
      // ID has a YYYY- prefix. Only non-standard IDs need a manual value.
      final autoYear = YearLevelAuto.derive(id);
      final resolvedYear = row.yearLevel.trim().isNotEmpty
          ? row.yearLevel.trim()
          : (autoYear ?? '');
      if (id.isEmpty ||
          row.firstName.trim().isEmpty ||
          row.lastName.trim().isEmpty ||
          row.course.trim().isEmpty ||
          resolvedYear.isEmpty) {
        skipped.add(row);
        skippedReasons.add('Missing required fields');
        continue;
      }

      final reason = await _importConflict(id, seen);
      if (reason != null) {
        skipped.add(row);
        skippedReasons.add(reason);
        continue;
      }

      try {
        final docId = await _db.insertStudent(Student(
          studentId: id,
          lastName: row.lastName.trim(),
          firstName: row.firstName.trim(),
          course: row.course.trim(),
          yearLevel: resolvedYear,
          passwordHash: kManagedByFirebaseAuth,
          salt: kManagedByFirebaseAuth,
          createdAt: DateTime.now(),
        ));
        await AuthLink.provisionStudent(
          studentId: id,
          password: kDefaultStudentPassword,
          docId: docId,
        );
      } catch (e) {
        skipped.add(row);
        skippedReasons.add('Login setup failed: $e');
        continue;
      }
      seen.add(id);
      imported++;
    }

    return StudentImportResult(
      imported: imported,
      skipped: skipped,
      skippedReasons: skippedReasons,
    );
  }

  /// Returns a reason string if [id] cannot be imported (duplicate inside
  /// the batch or already in the database), otherwise null.
  Future<String?> _importConflict(String id, Set<String> seen) async {
    if (seen.contains(id)) {
      return 'Duplicate within the file';
    }
    if (await _db.studentIdExists(id)) {
      return 'Already in the database';
    }
    return null;
  }

  /// Updates an existing student. A [newPassword] rotates the Firebase Auth
  /// login (version bump); a changed student ID moves the login mapping.
  /// Pass [previousStudentId] when the ID may have changed.
  Future<void> updateStudent(
    Student student, {
    String? newPassword,
    String? previousStudentId,
  }) async {
    final updated = Student(
      id: student.id,
      studentId: student.studentId,
      lastName: student.lastName,
      firstName: student.firstName,
      course: student.course,
      yearLevel: student.yearLevel,
      passwordHash: kManagedByFirebaseAuth,
      salt: kManagedByFirebaseAuth,
      createdAt: student.createdAt,
    );
    await _db.updateStudent(updated);

    final oldId = (previousStudentId ?? student.studentId).trim();
    final newId = student.studentId.trim();
    if (oldId != newId) {
      await AuthLink.moveStudentKey(
        oldStudentId: oldId,
        newStudentId: newId,
      );
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      if (student.id == null) {
        throw StudentException('Cannot change password: missing record id.');
      }
      await AuthLink.resetStudentPassword(
        studentId: newId,
        docId: student.id!,
        newPassword: newPassword,
      );
    }
  }

  Future<void> deleteStudent(Student student) async {
    await _db.deleteStudent(student.id!);
    await AuthLink.removeStudentLogin(student.studentId);
  }

  /// Students filtered by search text (ID or name), course and year level.
  Future<List<Student>> searchAndFilter({
    String? search,
    String? course,
    String? yearLevel,
  }) async {
    final all = await _db.getAllStudents();
    final query = search?.trim().toLowerCase() ?? '';

    return all.where((s) {
      final matchesSearch = query.isEmpty ||
          s.studentId.toLowerCase().contains(query) ||
          s.fullName.toLowerCase().contains(query);
      final matchesCourse = course == null || course.isEmpty || s.course == course;
      // Filter against the AUTO year level, not the stored fallback.
      final matchesYear = yearLevel == null ||
          yearLevel.isEmpty ||
          s.displayYearLevel == yearLevel;
      return matchesSearch && matchesCourse && matchesYear;
    }).toList();
  }
}

class StudentException implements Exception {
  final String message;

  const StudentException(this.message);

  @override
  String toString() => message;
}