import '../models/student_model.dart';
import '../utils/constants.dart';
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

    final creds = DatabaseServiceInterface.hashPassword(password);
    await _db.insertStudent(Student(
      studentId: cleanedId,
      lastName: lastName.trim(),
      firstName: firstName.trim(),
      course: course,
      yearLevel: yearLevel,
      passwordHash: creds['hash']!,
      salt: creds['salt']!,
      createdAt: DateTime.now(),
    ));
  }

  /// Inserts a batch of imported students. Every row is given the shared
  /// default password [kDefaultStudentPassword]; rows whose student ID is
  /// already in the database (or duplicated inside the same batch) are
  /// skipped and reported in the result.
  Future<StudentImportResult> importStudents(
    List<StudentImportRow> rows,
  ) async {
    var imported = 0;
    final skipped = <StudentImportRow>[];
    final skippedReasons = <String>[];
    final seen = <String>{}; // IDs already added earlier in this batch.

    for (final row in rows) {
      if (row.studentId.trim().isEmpty ||
          row.firstName.trim().isEmpty ||
          row.lastName.trim().isEmpty ||
          row.course.trim().isEmpty ||
          row.yearLevel.trim().isEmpty) {
        skipped.add(row);
        skippedReasons.add('Missing required fields');
        continue;
      }

      final id = row.studentId.trim();
      final reason = await _importConflict(id, seen);
      if (reason != null) {
        skipped.add(row);
        skippedReasons.add(reason);
        continue;
      }

      final creds = DatabaseServiceInterface.hashPassword(kDefaultStudentPassword);
      await _db.insertStudent(Student(
        studentId: id,
        lastName: row.lastName.trim(),
        firstName: row.firstName.trim(),
        course: row.course.trim(),
        yearLevel: row.yearLevel.trim(),
        passwordHash: creds['hash']!,
        salt: creds['salt']!,
        createdAt: DateTime.now(),
      ));
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

  /// Updates an existing student, optionally re-hashing a new password.
  Future<void> updateStudent(
    Student student, {
    String? newPassword,
  }) async {
    var updated = student;
    if (newPassword != null && newPassword.isNotEmpty) {
      final creds = DatabaseServiceInterface.hashPassword(newPassword);
      updated = Student(
        id: student.id,
        studentId: student.studentId,
        lastName: student.lastName,
        firstName: student.firstName,
        course: student.course,
        yearLevel: student.yearLevel,
        passwordHash: creds['hash']!,
        salt: creds['salt']!,
        createdAt: student.createdAt,
      );
    }
    await _db.updateStudent(updated);
  }

  Future<void> deleteStudent(Student student) =>
      _db.deleteStudent(student.id!);

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
      final matchesYear =
          yearLevel == null || yearLevel.isEmpty || s.yearLevel == yearLevel;
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