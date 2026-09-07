import '../models/attendance_model.dart';
import '../models/event_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/password_hash.dart';

/// Abstract interface for database services.
/// Implementations: [DatabaseService] (SQLite), [SupabaseDatabaseService] (Supabase).
abstract class DatabaseServiceInterface {
  // Users (Admins)
  Future<User?> getUserByUsername(String username);
  Future<List<User>> getAllUsers();
  Future<String> insertUser(User user);
  Future<Map<String, String>> updateUserPassword(String userId, String plainPassword);
  Future<bool> updateUser(User user, {String? newUsername, String? newRole});
  Future<bool> deleteUser(String userId, {String? currentUserId});

  // Students
  Future<Student?> getStudentById(String studentId);
  Future<List<Student>> getAllStudents();
  Future<bool> studentIdExists(String studentId);
  Future<String> insertStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);
  Future<int> countStudents();

  // Courses
  Future<List<Course>> getAllCourses();
  Future<bool> courseNameExists(String courseName);
  Future<String> insertCourse(Course course);
  Future<void> updateCourse(Course course);
  Future<void> deleteCourse(String id);

  // Events
  Future<AttendanceEvent?> getActiveEvent();
  Future<List<AttendanceEvent>> getAllEvents();
  Future<String> insertEvent(String name, {bool setActive = false, String flowType = EventFlowType.oneTime});
  Future<void> updateEvent(AttendanceEvent event);
  Future<void> setActiveEvent(String id);
  Future<bool> deleteEvent(String id);
  Future<AttendanceEvent> ensureActiveEvent();
  Future<Map<String, int>> courseCountsForEvent(String eventId);
  Future<Map<String, int>> attendanceCountByEvent();

  // Attendance
  Future<Attendance?> findAttendance(String studentId, String date, String eventId, String checkType);
  Future<String> insertAttendance(Attendance attendance);
  Future<List<Attendance>> recentAttendance({int limit = 8});
  Future<List<Attendance>> queryAttendance({
    String? search,
    String? date,
    String? course,
    String? yearLevel,
    String? status,
    String? eventId,
  });
  Future<List<String>> distinctAttendanceDates();
  Future<List<Attendance>> attendanceForStudent(String studentId);
  Future<int> countAttendance();
  Future<int> countAttendanceOn(String date, {String? eventId});

  // Seed data
  Future<void> seedDemoData();
  
// Password hashing
  static Map<String, String> hashPassword(String password, {String? salt}) {
    return PasswordHash.hash(password, salt: salt);
  }

  static bool verifyPassword(String password, String salt, String hash) {
    return PasswordHash.verify(password, salt, hash);
  }
}