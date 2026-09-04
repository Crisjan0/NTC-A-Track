import '../models/attendance_model.dart';
import '../models/event_model.dart';
import '../models/student_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'database_service.dart';

/// Outcome of attempting to record attendance from a QR scan.
enum AttendanceResultType { success, alreadyRecorded, studentNotFound }

class AttendanceResult {
  final AttendanceResultType type;
  final Attendance? attendance;
  final Student? student;

  /// Name of the event the scan was recorded (or would have been recorded) to.
  final String? eventName;

  const AttendanceResult({
    required this.type,
    this.attendance,
    this.student,
    this.eventName,
  });
}

/// Aggregated stats shown on the admin dashboard.
class DashboardStats {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int totalAttendance;

  const DashboardStats({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.totalAttendance,
  });
}

/// Attendance summary shown on the student dashboard.
class StudentSummary {
  final int total;
  final int present;
  final int absent;
  final double rate;

  const StudentSummary({
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
  });
}

/// Attendance recording, stats and history queries.
class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  final DatabaseService _db = DatabaseService.instance;

  /// Core scan flow: resolve student, check today's record for the active
  /// event, insert if new.
  ///
  /// Returns the outcome so the UI can show the right confirmation. The
  /// active event is used automatically (creating a default one if none
  /// exists), so "one event at a time" scanning just works.
  Future<AttendanceResult> recordFromScan(String rawQrValue) async {
    final studentId = rawQrValue.trim();
    if (studentId.isEmpty) {
      return const AttendanceResult(type: AttendanceResultType.studentNotFound);
    }

    final student = await _db.getStudentById(studentId);
    if (student == null) {
      return const AttendanceResult(type: AttendanceResultType.studentNotFound);
    }

    final event = await _db.ensureActiveEvent();
    final now = DateTime.now();
    final date = Formatters.dbDate(now);

    final existing = await _db.findAttendance(studentId, date, event.id!);
    if (existing != null) {
      return AttendanceResult(
        type: AttendanceResultType.alreadyRecorded,
        attendance: existing,
        student: student,
        eventName: event.name,
      );
    }

    final record = Attendance(
      studentId: studentId,
      date: now,
      time: now,
      status: AttendanceStatus.present,
      eventId: event.id,
      createdAt: now,
    );
    await _db.insertAttendance(record);

    return AttendanceResult(
      type: AttendanceResultType.success,
      attendance: record,
      student: student,
      eventName: event.name,
    );
  }

  // ---------------------------------------------------------------- events

  /// The event scans are currently recorded to (always non-null: a default
  /// event is created if needed).
  Future<AttendanceEvent> activeEvent() => _db.ensureActiveEvent();

  Future<List<AttendanceEvent>> allEvents() => _db.getAllEvents();

  Future<Map<int, int>> attendanceCountByEvent() =>
      _db.attendanceCountByEvent();

  /// Distinct courses that have attendance records for [eventId], with counts.
  Future<Map<String, int>> courseCountsForEvent(int eventId) =>
      _db.courseCountsForEvent(eventId);

  Future<int> createEvent(String name, {bool setActive = false}) =>
      _db.insertEvent(name, setActive: setActive);

  Future<void> setActiveEvent(int id) => _db.setActiveEvent(id);

  /// False if the event is currently active (which can never be deleted).
  Future<bool> deleteEvent(int id) => _db.deleteEvent(id);

  Future<DashboardStats> dashboardStats() async {
    final totalStudents = await _db.countStudents();
    final presentToday =
        await _db.countAttendanceOn(Formatters.dbDate(DateTime.now()));
    return DashboardStats(
      totalStudents: totalStudents,
      presentToday: presentToday,
      absentToday: (totalStudents - presentToday).clamp(0, totalStudents),
      totalAttendance: await _db.countAttendance(),
    );
  }

  Future<List<Attendance>> recentAttendance({int limit = 8}) =>
      _db.recentAttendance(limit: limit);

  Future<List<Attendance>> queryAttendance({
    String? search,
    String? date,
    String? course,
    String? yearLevel,
    String? status,
    int? eventId,
  }) =>
      _db.queryAttendance(
        search: search,
        date: date,
        course: course,
        yearLevel: yearLevel,
        status: status,
        eventId: eventId,
      );

  /// A student's own history: every school day (dates that appear anywhere
  /// in attendance) marked PRESENT or ABSENT for this student.
  Future<List<Attendance>> studentHistory(String studentId) async {
    final records = await _db.attendanceForStudent(studentId);
    final byDate = {
      for (final r in records) Formatters.dbDate(r.date): r,
    };

    final schoolDays = await _db.distinctAttendanceDates();
    final history = <Attendance>[];

    for (final day in schoolDays) {
      final parsed = DateTime.parse(day);
      final existing = byDate[day];
      if (existing != null) {
        history.add(existing);
      } else {
        history.add(Attendance(
          studentId: studentId,
          date: parsed,
          time: parsed,
          status: AttendanceStatus.absent,
          createdAt: parsed,
        ));
      }
    }
    return history;
  }

  Future<StudentSummary> studentSummary(String studentId) async {
    final records = await _db.attendanceForStudent(studentId);
    final present = records.length;
    final schoolDays = await _db.distinctAttendanceDates();
    final absent = schoolDays.length - present;
    final total = present + absent;
    final rate = total == 0
        ? 0.0
        : (present / total) * 100;
    return StudentSummary(
      total: total,
      present: present,
      absent: absent < 0 ? 0 : absent,
      rate: rate,
    );
  }
}