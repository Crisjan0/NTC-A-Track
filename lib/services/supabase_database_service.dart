import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/supabase_config.dart';
import 'database_service_interface.dart';
import '../models/attendance_model.dart';
import '../models/event_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/password_hash.dart';

/// Supabase database service (cloud PostgreSQL).
///
/// Tables:
///  - users: admin accounts
///  - students: student records (credentials included for demo login)
///  - events: attendance events (e.g. "Intrams"); exactly one is
///    active at a time and QR scans are recorded to it
///  - attendance: one record per student per day per event (UNIQUE
///    constraint prevents duplicate attendance at the database level)
class SupabaseDatabaseService implements DatabaseServiceInterface {
  SupabaseDatabaseService._();

  static final SupabaseDatabaseService instance = SupabaseDatabaseService._();

  static const String kUsersTable = 'users';
  static const String kStudentsTable = 'students';
  static const String kEventsTable = 'events';
  static const String kAttendanceTable = 'attendance';
  static const String kCoursesTable = 'courses';

  /// Default event used on first launch and as a fallback when the admin
  /// has not created (and activated) their own event yet.
  static const String defaultEventName = 'General Attendance';

  SupabaseClient get _client => SupabaseConfig.client;

  /// Initialize Supabase connection
  static Future<void> initialize() async {
    await SupabaseConfig.initialize();
  }

  /// Returns a random salt + SHA-256 hash of salt+password.
  static Map<String, String> hashPassword(
    String password, {
    String? salt,
  }) {
    return PasswordHash.hash(password, salt: salt);
  }

  /// Verifies a plain-text password against a stored hash + salt.
  static bool verifyPassword(String password, String salt, String hash) {
    return PasswordHash.verify(password, salt, hash);
  }

  // ---------------------------------------------------------------- Users (Admins)

  Future<User?> getUserByUsername(String username) async {
    final response = await _client
        .from(kUsersTable)
        .select()
        .eq('username', username.trim())
        .limit(1)
        .maybeSingle();
    return response != null ? User.fromMap(response) : null;
  }

  /// All admin accounts, newest first.
  Future<List<User>> getAllUsers() async {
    final response = await _client
        .from(kUsersTable)
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => User.fromMap(e)).toList();
  }

  /// Inserts a new admin user. Returns the new user's ID.
  Future<String> insertUser(User user) async {
    final response = await _client
        .from(kUsersTable)
        .insert(user.toMap())
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Update an existing admin's password. Returns the new salt + hash map so
  /// callers can also update their own in-memory copy.
  Future<Map<String, String>> updateUserPassword(
    String userId,
    String plainPassword,
  ) async {
    final creds = hashPassword(plainPassword);
    await _client.from(kUsersTable).update({
      'password_hash': creds['hash'],
      'salt': creds['salt'],
    }).eq('id', int.parse(userId));
    return creds;
  }

  /// Update an existing admin account's metadata (username and/or role).
  /// Usernames are unique, so a collision with another account is rejected.
  Future<bool> updateUser(
    User user, {
    String? newUsername,
    String? newRole,
  }) async {
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      final collision = await _client
          .from(kUsersTable)
          .select('id')
          .eq('username', newUsername.trim())
          .neq('id', user.id!)
          .maybeSingle();
      if (collision != null) return false;
    }

    final updates = <String, dynamic>{};
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      updates['username'] = newUsername.trim();
    }
    if (newRole != null && newRole.trim().isNotEmpty) {
      updates['role'] = newRole.trim();
    }

    if (updates.isNotEmpty) {
      await _client.from(kUsersTable).update(updates).eq('id', user.id!);
    }
    return true;
  }

  /// Deletes an admin account. The caller is responsible for preventing an
  /// admin from deleting their own account (caller supplies [currentUserId]).
  Future<bool> deleteUser(String userId, {String? currentUserId}) async {
    if (currentUserId == userId) return false;
    final response = await _client
        .from(kUsersTable)
        .select('id')
        .eq('id', int.parse(userId))
        .maybeSingle();
    if (response == null) return false;
    await _client.from(kUsersTable).delete().eq('id', int.parse(userId));
    return true;
  }

  // ---------------------------------------------------------------- Students

  Future<Student?> getStudentById(String studentId) async {
    final response = await _client
        .from(kStudentsTable)
        .select()
        .eq('student_id', studentId.trim())
        .limit(1)
        .maybeSingle();
    return response != null ? Student.fromMap(response) : null;
  }

  Future<List<Student>> getAllStudents() async {
    final response = await _client
        .from(kStudentsTable)
        .select()
        .order('student_id', ascending: true);
    return (response as List).map((e) => Student.fromMap(e)).toList();
  }

  Future<bool> studentIdExists(String studentId) async {
    final response = await _client
        .from(kStudentsTable)
        .select('student_id')
        .eq('student_id', studentId.trim())
        .limit(1)
        .maybeSingle();
    return response != null;
  }

  Future<String> insertStudent(Student student) async {
    final response = await _client
        .from(kStudentsTable)
        .insert(student.toMap())
        .select('id, student_id')
        .single();
    return response['id'] as String;
  }

  /// Get student's UUID id by their text student_id.
  Future<String?> _getStudentUuidByStudentId(String studentId) async {
    final response = await _client
        .from(kStudentsTable)
        .select('id')
        .eq('student_id', studentId.trim())
        .limit(1)
        .maybeSingle();
    return response?['id'] as String?;
  }

  Future<void> updateStudent(Student student) async {
    await _client
        .from(kStudentsTable)
        .update(student.toMap())
        .eq('id', student.id!);
  }

  Future<void> deleteStudent(String id) async {
    // Attendance rows cascade-delete via FK.
    await _client.from(kStudentsTable).delete().eq('id', id);
  }

  Future<int> countStudents() async {
    final count = await _client
        .from(kStudentsTable)
        .count();
    return count;
  }

  // ---------------------------------------------------------------- Courses

  Future<List<Course>> getAllCourses() async {
    final response = await _client
        .from(kCoursesTable)
        .select()
        .order('course_name', ascending: true);
    return (response as List).map((e) => Course.fromMap(e)).toList();
  }

  Future<bool> courseNameExists(String courseName) async {
    final response = await _client
        .from(kCoursesTable)
        .select('id')
        .eq('course_name', courseName.trim())
        .limit(1)
        .maybeSingle();
    return response != null;
  }

  Future<String> insertCourse(Course course) async {
    final response = await _client
        .from(kCoursesTable)
        .insert(course.toMap())
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateCourse(Course course) async {
    await _client
        .from(kCoursesTable)
        .update(course.toMap())
        .eq('id', course.id!);
  }

  Future<void> deleteCourse(String id) async {
    await _client.from(kCoursesTable).delete().eq('id', id);
  }

  // ---------------------------------------------------------------- Events

  /// The single event QR scans currently record to, if any.
  Future<AttendanceEvent?> getActiveEvent() async {
    final response = await _client
        .from(kEventsTable)
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    return response != null ? AttendanceEvent.fromMap(response) : null;
  }

  Future<List<AttendanceEvent>> getAllEvents() async {
    final response = await _client
        .from(kEventsTable)
        .select()
        .order('is_active', ascending: false)
        .order('created_at', ascending: true);
    return (response as List).map((e) => AttendanceEvent.fromMap(e)).toList();
  }

  /// Creates an event, optionally activating it right away.
  Future<String> insertEvent(
    String name, {
    bool setActive = false,
    String flowType = EventFlowType.oneTime,
  }) async {
    final db = _client;
    final id = await _insertEvent(
      db,
      name: name,
      isActive: setActive,
      flowType: flowType,
    );
    return id;
  }

  /// Updates an event's name / flow type.
  Future<void> updateEvent(AttendanceEvent event) async {
    await _client.from(kEventsTable).update({
      'name': event.name.trim(),
      'flow_type': event.flowType,
    }).eq('id', event.id!);
  }

  /// Makes [id] the active event (all others become inactive).
  Future<void> setActiveEvent(String id) async {
    await _client.from(kEventsTable).update({'is_active': false});
    await _client.from(kEventsTable).update({'is_active': true}).eq('id', id);
  }

  /// Deletes a non-active event. Its attendance rows are kept but lose the
  /// event tag (FK ON DELETE SET NULL). Returns false if the event is
  /// currently active, so the active event can never be removed.
  Future<bool> deleteEvent(String id) async {
    final response = await _client
        .from(kEventsTable)
        .select('is_active')
        .eq('id', id)
        .limit(1)
        .maybeSingle();
    if (response == null) return false;
    if (response['is_active'] == true) return false;
    await _client.from(kEventsTable).delete().eq('id', id);
    return true;
  }

  /// The active event, creating (and activating) the default one if the
  /// admin has not set up any event yet.
  Future<AttendanceEvent> ensureActiveEvent() async {
    final active = await getActiveEvent();
    if (active != null) return active;

    final events = await getAllEvents();
    if (events.isNotEmpty) {
      await setActiveEvent(events.first.id!);
      return events.first;
    }

    final id = await insertEvent(defaultEventName, setActive: true);
    return AttendanceEvent(
      id: id,
      name: defaultEventName,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  /// Distinct courses that have attendance records for [eventId], with the
  /// number of *distinct students* per course (drill-down: event → course →
  /// students). DISTINCT keeps Time In/Out events from counting the same
  /// student four times.
  Future<Map<String, int>> courseCountsForEvent(String eventId) async {
    final response = await _client
        .from(kAttendanceTable)
        .select('''
          student_id,
          students!inner(course)
        ''')
        .eq('event_id', eventId);

    final Map<String, Set<String>> courseStudents = {};
    for (final row in response as List) {
      final student = row['students'] as Map<String, dynamic>;
      final course = student['course'] as String;
      final studentId = row['student_id'] as String;
      courseStudents.putIfAbsent(course, () => {}).add(studentId);
    }

    return {
      for (final entry in courseStudents.entries) entry.key: entry.value.length,
    };
  }

/// Distinct-student attendance count per event, keyed by event id.
  Future<Map<String, int>> attendanceCountByEvent() async {
    final response = await _client
        .from(kAttendanceTable)
        .select('event_id, student_id, students!inner(student_id)')
        .not('event_id', 'is', null);

    final Map<String, Set<String>> eventStudents = {};
    for (final row in response as List) {
      final eventId = row['event_id'] as String;
      final student = row['students'] as Map<String, dynamic>;
      final studentId = student['student_id'] as String;
      eventStudents.putIfAbsent(eventId, () => {}).add(studentId);
    }

    return {
      for (final entry in eventStudents.entries) entry.key: entry.value.length,
    };
  }

  Future<String> _insertEvent(
    SupabaseClient db, {
    required String name,
    bool isActive = false,
    String flowType = EventFlowType.oneTime,
  }) async {
    final response = await db.from(kEventsTable).insert({
      'name': name.trim(),
      'is_active': isActive,
      'flow_type': flowType,
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    return response['id'] as String;
  }

  // ---------------------------------------------------------------- Attendance

  /// Existing record for a student on a given date, event and check type.
  Future<Attendance?> findAttendance(
    String studentId,
    String date,
    String eventId,
    String checkType,
  ) async {
    final studentUuid = await _getStudentUuidByStudentId(studentId);
    if (studentUuid == null) return null;

    final response = await _client
        .from(kAttendanceTable)
        .select()
        .eq('student_id', studentUuid)
        .eq('date', date)
        .eq('event_id', eventId)
        .eq('check_type', checkType)
        .limit(1)
        .maybeSingle();
    return response != null ? Attendance.fromMap(response) : null;
  }

  Future<String> insertAttendance(Attendance attendance) async {
    final studentUuid = await _getStudentUuidByStudentId(attendance.studentId);
    if (studentUuid == null) {
      throw Exception('Student not found: ${attendance.studentId}');
    }

    final map = attendance.toMap();
    map['student_id'] = studentUuid;

    final response = await _client
        .from(kAttendanceTable)
        .insert(map)
        .select('id')
        .single();
    return response['id'] as String;
  }

/// Recent attendance joined with student + event names, newest first.
  Future<List<Attendance>> recentAttendance({int limit = 8}) async {
    final response = await _client
        .from(kAttendanceTable)
        .select('''
          *,
          students!inner(id, first_name, last_name, course, year_level, student_id),
          events!left(name)
        ''')
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(limit);

    return (response as List).map((row) {
      final attendance = Attendance.fromMap(row);
      final student = row['students'] as Map<String, dynamic>;
      final event = row['events'] as Map<String, dynamic>?;
      return attendance.copyWith(
        studentName: '${student['first_name']} ${student['last_name']}',
        course: student['course'] as String?,
        yearLevel: student['year_level'] as String?,
        eventName: event?['name'] as String?,
      );
    }).toList();
  }

  /// All attendance records joined with student + event names, newest first,
  /// optionally filtered by search text, date, course, year level, status
  /// or event.
  Future<List<Attendance>> queryAttendance({
    String? search,
    String? date,
    String? course,
    String? yearLevel,
    String? status,
    String? eventId,
  }) async {
    var query = _client.from(kAttendanceTable).select('''
      *,
      students!inner(id, first_name, last_name, course, year_level, student_id),
      events!left(name)
    ''');

    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim()}%';
      query = query.or('students.first_name.ilike.$q,students.last_name.ilike.$q,students.student_id.ilike.$q');
    }
    if (date != null && date.isNotEmpty) {
      query = query.eq('date', date);
    }
    if (course != null && course.isNotEmpty) {
      query = query.eq('students.course', course);
    }
    if (yearLevel != null && yearLevel.isNotEmpty) {
      query = query.eq('students.year_level', yearLevel);
    }
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }

    final response = await query
        .order('date', ascending: false)
        .order('time', ascending: false);

    return (response as List).map((row) {
      final attendance = Attendance.fromMap(row);
      final student = row['students'] as Map<String, dynamic>;
      final event = row['events'] as Map<String, dynamic>?;
      return attendance.copyWith(
        studentName: '${student['first_name']} ${student['last_name']}',
        course: student['course'] as String?,
        yearLevel: student['year_level'] as String?,
        eventName: event?['name'] as String?,
      );
    }).toList();
  }

  /// All distinct dates that have any attendance record (i.e. "school days").
  Future<List<String>> distinctAttendanceDates() async {
    final response = await _client
        .from(kAttendanceTable)
        .select('date')
        .order('date', ascending: false);
    
    final Set<String> dates = {};
    for (final row in response as List) {
      dates.add(row['date'] as String);
    }
    return dates.toList();
  }

/// A student's own attendance history, newest first, with event names.
  Future<List<Attendance>> attendanceForStudent(String studentId) async {
    final studentUuid = await _getStudentUuidByStudentId(studentId);
    if (studentUuid == null) return [];

    final response = await _client
        .from(kAttendanceTable)
        .select('''
          *,
          events!left(name)
        ''')
        .eq('student_id', studentUuid)
        .order('date', ascending: false)
        .order('time', ascending: false);

    return (response as List).map((row) {
      final attendance = Attendance.fromMap(row);
      final event = row['events'] as Map<String, dynamic>?;
      return attendance.copyWith(
        eventName: event?['name'] as String?,
      );
    }).toList();
  }

  Future<int> countAttendance() async {
    return await _client
        .from(kAttendanceTable)
        .count();
  }

  Future<int> countAttendanceOn(String date, {String? eventId}) async {
    var query = _client
        .from(kAttendanceTable)
        .select('student_id')
        .eq('date', date);

    if (eventId != null) {
      query = query.eq('event_id', eventId);
    }

    final response = await query.count();
    return response.count;
  }

  // ---------------------------------------------------------------- Seed Data

  /// Seeds demo data on first launch so the app is usable immediately:
  /// an admin account, default courses, five students, a default active event, and
  /// attendance history for this week.
  Future<void> seedDemoData() async {
    // Check if already seeded
    final existingUser = await _client
        .from(kUsersTable)
        .select('id')
        .limit(1)
        .maybeSingle();
    if (existingUser != null) return;

    final adminHash = hashPassword(DemoCredentials.adminPassword, salt: null);
    await _client.from(kUsersTable).insert({
      'username': DemoCredentials.adminUsername,
      'password_hash': adminHash['hash'],
      'salt': adminHash['salt'],
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed default courses (idempotent via UNIQUE constraint).
    for (final courseName in kCourses) {
      try {
        await _client.from(kCoursesTable).insert({
          'course_name': courseName,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Ignore duplicates: course already seeded.
      }
    }

    final demoStudents = [
      ('2026-0001', 'Dela Cruz', 'Juan', kCourses[0], kYearLevels[1]),
      ('2026-0002', 'Santos', 'Maria', kCourses[1], kYearLevels[0]),
      ('2026-0003', 'Reyes', 'Jose', kCourses[0], kYearLevels[2]),
      ('2026-0004', 'Garcia', 'Ana', kCourses[2], kYearLevels[1]),
      ('2026-0005', 'Mendoza', 'Carlos', kCourses[1], kYearLevels[3]),
    ];

    final now = DateTime.now();
    // Insert students and collect their UUIDs
    final studentUuids = <String, String>{}; // student_id (text) -> UUID
    for (final s in demoStudents) {
      final creds = hashPassword(DemoCredentials.studentPassword, salt: null);
      final response = await _client.from(kStudentsTable).insert({
        'student_id': s.$1,
        'last_name': s.$2,
        'first_name': s.$3,
        'course': s.$4,
        'year_level': s.$5,
        'password_hash': creds['hash'],
        'salt': creds['salt'],
        'created_at': now.toIso8601String(),
      }).select('id, student_id').single();
      studentUuids[response['student_id'] as String] = response['id'] as String;
    }

    // Every seeded record belongs to the default (active) event.
    final defaultEventId = await _insertEvent(
      _client,
      name: defaultEventName,
      isActive: true,
    );

    // A few days of history so dashboards and stats look alive.
    // dayOffset 0 = today, 1 = yesterday, etc. Maps: student index (1-based)
    // → presence that day.
    const history = {
      0: {1: true, 2: true, 4: true}, // today: 3 present, 2 absent
      1: {1: true, 2: true, 3: true, 4: true},
      2: {1: true, 2: true, 3: true, 5: true},
      3: {2: true, 3: true, 4: true, 5: true},
    };

    history.forEach((offset, present) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: offset));
      final recordTime =
          DateTime(day.year, day.month, day.day, 8, 5 + offset); // ~8:05–8:10
      for (final studentIdx in present.keys) {
        final studentId = '2026-000$studentIdx';
        final studentUuid = studentUuids[studentId];
        if (studentUuid == null) continue;
        _client.from(kAttendanceTable).insert({
          'student_id': studentUuid,
          'date': Formatters.dbDate(day),
          'time': '${recordTime.hour.toString().padLeft(2, '0')}:'
              '${recordTime.minute.toString().padLeft(2, '0')}',
          'status': AttendanceStatus.present,
          'check_type': CheckType.present,
          'event_id': defaultEventId,
          'created_at': day.toIso8601String(),
        });
      }
    });

    // Demo Time In/Out event so the AM/PM flow is visible right away on
    // fresh installs. Two students with a full AM/PM in/out day today and
    // yesterday, tagged to a non-active "Intrams" event.
    final intramsId = await _insertEvent(
      _client,
      name: 'Intrams',
      isActive: false,
      flowType: EventFlowType.timeInOut,
    );
    const intramsStudents = ['2026-0002', '2026-0004'];
    const intramsCheckTimes = {
      CheckType.amIn: 8,
      CheckType.amOut: 12,
      CheckType.pmIn: 13,
      CheckType.pmOut: 17,
    };
    for (final offset in [0, 1]) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: offset));
      for (var i = 0; i < intramsStudents.length; i++) {
        final studentId = intramsStudents[i];
        final studentUuid = studentUuids[studentId];
        if (studentUuid == null) continue;
        intramsCheckTimes.forEach((checkType, hour) {
          _client.from(kAttendanceTable).insert({
            'student_id': studentUuid,
            'date': Formatters.dbDate(day),
            'time': '${hour.toString().padLeft(2, '0')}:'
                '${(i * 5).toString().padLeft(2, '0')}',
            'status': AttendanceStatus.present,
            'check_type': checkType,
            'event_id': intramsId,
            'created_at': day.toIso8601String(),
          });
        });
      }
    }
  }
}