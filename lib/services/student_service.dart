import '../models/student_model.dart';
import 'database_service.dart';

/// CRUD + search operations for students.
class StudentService {
  StudentService._();

  static final StudentService instance = StudentService._();

  final DatabaseService _db = DatabaseService.instance;

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

    final creds = DatabaseService.hashPassword(password);
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

  /// Updates an existing student, optionally re-hashing a new password.
  Future<void> updateStudent(
    Student student, {
    String? newPassword,
  }) async {
    var updated = student;
    if (newPassword != null && newPassword.isNotEmpty) {
      final creds = DatabaseService.hashPassword(newPassword);
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