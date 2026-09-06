import '../models/course_model.dart';
import 'database_service.dart';

/// CRUD and listing operations for academic courses.
class CourseService {
  CourseService._();

  static final CourseService instance = CourseService._();

  final DatabaseService _db = DatabaseService.instance;

  /// All courses, sorted by name.
  Future<List<Course>> getAllCourses() => _db.getAllCourses();

  /// Whether a course with [name] already exists.
  Future<bool> nameExists(String name) => _db.courseNameExists(name);

  /// Inserts a new course. Returns the new row id.
  Future<int> addCourse(String name) async {
    final course = Course(
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    return _db.insertCourse(course);
  }

  /// Updates an existing course's name. Returns affected row count.
  Future<int> updateCourse(Course course, String newName) async {
    final updated = Course(
      id: course.id,
      name: newName.trim(),
      createdAt: course.createdAt,
    );
    return _db.updateCourse(updated);
  }

  /// Deletes the course with [id]. Returns affected row count.
  Future<int> deleteCourse(int id) => _db.deleteCourse(id);
}
