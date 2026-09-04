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
///
/// [presentToday] / [absentToday] are scoped to the *active event* so the
/// dashboard agrees with what the admin is actually scanning for (e.g.
/// Intrams), instead of mixing in records from other events.
class DashboardStats {
  final int totalStudents;
  final int presentToday;
  final int absentToday;
  final int totalAttendance;

  /// Name of the event the today counts refer to.
  final String? eventName;

  const DashboardStats({
    required this.totalStudents,
    required this.presentToday,
    required this.absentToday,
    required this.totalAttendance,
    this.eventName,
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

/// One event a student has attendance records for, with how many times
/// they attended it.
class StudentEventSummary {
  final AttendanceEvent event;
  final int timesAttended;

  const StudentEventSummary({
    required this.event,
    required this.timesAttended,
  });
}

/// Attendance recording, stats and history queries.
class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  final DatabaseService _db = DatabaseService.instance;

  /// Core scan flow: resolve student, check today's record for the active
  /// event + check type, insert if new.
  ///
  /// [checkType] selects what is being recorded: for one-time events it is
  /// ignored (always [CheckType.present]); for Time In/Out events it must be
  /// one of the AM/PM check-in/check-out combinations (defaults to
  /// [CheckType.amIn]).
  Future<AttendanceResult> recordFromScan(
    String rawQrValue, {
    String? checkType,
  }) async {
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
    final effectiveCheck =
        event.usesTimeInOut ? (checkType ?? CheckType.amIn) : CheckType.present;

    final existing =
        await _db.findAttendance(studentId, date, event.id!, effectiveCheck);
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
      checkType: effectiveCheck,
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

  Future<int> createEvent(
    String name, {
    bool setActive = false,
    String flowType = EventFlowType.oneTime,
  }) =>
      _db.insertEvent(name, setActive: setActive, flowType: flowType);

  Future<void> updateEvent(AttendanceEvent event) => _db.updateEvent(event);

  Future<void> setActiveEvent(int id) => _db.setActiveEvent(id);

  /// False if the event is currently active (which can never be deleted).
  Future<bool> deleteEvent(int id) => _db.deleteEvent(id);

  Future<DashboardStats> dashboardStats() async {
    final totalStudents = await _db.countStudents();
    final event = await _db.ensureActiveEvent();
    final today = Formatters.dbDate(DateTime.now());
    final presentToday = await _db.countAttendanceOn(today, eventId: event.id);
    return DashboardStats(
      totalStudents: totalStudents,
      presentToday: presentToday,
      absentToday: (totalStudents - presentToday).clamp(0, totalStudents),
      totalAttendance: await _db.countAttendance(),
      eventName: event.name,
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
  ///
  /// Days with records return *all* of them (e.g. the AM/PM Time In/Out
  /// checks), so the UI can group them into a single day card.
  Future<List<Attendance>> studentHistory(String studentId) async {
    final records = await _db.attendanceForStudent(studentId);
    final byDate = <String, List<Attendance>>{};
    for (final r in records) {
      byDate.putIfAbsent(Formatters.dbDate(r.date), () => []).add(r);
    }

    final schoolDays = await _db.distinctAttendanceDates();
    final history = <Attendance>[];

    for (final day in schoolDays) {
      final parsed = DateTime.parse(day);
      final dayRecords = byDate[day];
      if (dayRecords != null && dayRecords.isNotEmpty) {
        history.addAll(dayRecords);
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

  /// The events a student has attended (has PRESENT records for), newest
  /// created first, each with the number of times attended.
  Future<List<StudentEventSummary>> studentEvents(String studentId) async {
    final records = await _db.attendanceForStudent(studentId);
    final events = await _db.getAllEvents();
    final byId = {for (final e in events) if (e.id != null) e.id!: e};

    final counts = <int, int>{};
    final seenDays = <String>{};
    for (final r in records) {
      final id = r.eventId;
      if (id == null) continue;
      // One day = one attendance, even for Time In/Out events where a
      // student produces several records (AM/PM in/out) per day.
      final dayKey = '${r.date.toIso8601String().substring(0, 10)}#$id';
      if (seenDays.add(dayKey)) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }

    final result = <StudentEventSummary>[
      for (final entry in counts.entries)
        if (byId[entry.key] != null)
          StudentEventSummary(
            event: byId[entry.key]!,
            timesAttended: entry.value,
          ),
    ];
    result.sort((a, b) {
      final active = (b.event.isActive ? 1 : 0) - (a.event.isActive ? 1 : 0);
      return active != 0
          ? active
          : b.timesAttended.compareTo(a.timesAttended);
    });
    return result;
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