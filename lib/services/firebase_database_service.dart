import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'auth_link.dart';
import 'database_service_interface.dart';
import '../models/attendance_model.dart';
import '../models/event_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';

/// Firestore database service (Firebase).
///
/// Collections:
///  - users: admin accounts      { username, password_hash, salt, role, created_at }
///  - students: student records  { student_id, last_name, first_name, course, year_level, password_hash, salt, created_at }
///  - courses:                   { course_name, created_at }
///  - events:                    { name, is_active, flow_type, created_at }
///  - attendance:                { student_id (text e.g. "2026-0001"), date (yyyy-MM-dd), time (HH:mm),
///                                 status, check_type, event_id (event docId), created_at }
///
/// Document IDs are Firestore auto-IDs (strings). Unlike the old Supabase
/// UUID setup, attendance stores the human-readable `student_id` text
/// directly, so no UUID lookup table is needed.
class FirebaseDatabaseService implements DatabaseServiceInterface {
  FirebaseDatabaseService._();

  static final FirebaseDatabaseService instance = FirebaseDatabaseService._();

  static const String kUsersTable = 'users';
  static const String kStudentsTable = 'students';
  static const String kEventsTable = 'events';
  static const String kAttendanceTable = 'attendance';
  static const String kCoursesTable = 'courses';

  static const String defaultEventName = 'General Attendance';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Firebase.initializeApp() is done in FirebaseConfig before this.
  }

  // ---------------------------------------------------------- map helpers

  static Map<String, dynamic> _withId(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    return data;
  }

  /// Firestore `add()` needs a map without the local `id` key.
  static Map<String, dynamic> _stripId(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.remove('id');
    return copy;
  }

  // ---------------------------------------------------------------- Users

  @override
  Future<User?> getUserByUsername(String username) async {
    final snap = await _db
        .collection(kUsersTable)
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return User.fromMap(_withId(snap.docs.first));
  }

  @override
  Future<List<User>> getAllUsers() async {
    final snap = await _db.collection(kUsersTable).get();
    final users = snap.docs.map((d) => User.fromMap(_withId(d))).toList();
    users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return users;
  }

  @override
  Future<String> insertUser(User user) async {
    final ref = await _db
        .collection(kUsersTable)
        .add(_stripId(user.toMap()));
    return ref.id;
  }

  @override
  Future<bool> updateUser(
    User user, {
    String? newUsername,
    String? newRole,
  }) async {
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      final clash = await _db
          .collection(kUsersTable)
          .where('username', isEqualTo: newUsername.trim())
          .get();
      if (clash.docs.any((d) => d.id != user.id)) return false;
    }
    final updates = <String, dynamic>{};
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      updates['username'] = newUsername.trim();
    }
    if (newRole != null && newRole.trim().isNotEmpty) {
      updates['role'] = newRole.trim();
    }
    if (updates.isNotEmpty) {
      await _db.collection(kUsersTable).doc(user.id!).update(updates);
    }
    return true;
  }

  @override
  Future<bool> deleteUser(String userId, {String? currentUserId}) async {
    if (currentUserId == userId) return false;
    final doc =
        await _db.collection(kUsersTable).doc(userId).get();
    if (!doc.exists) return false;
    await _db.collection(kUsersTable).doc(userId).delete();
    return true;
  }

  // --------------------------------------------------------------- Students

  @override
  Future<Student?> getStudentById(String studentId) async {
    final snap = await _db
        .collection(kStudentsTable)
        .where('student_id', isEqualTo: studentId.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Student.fromMap(_withId(snap.docs.first));
  }

  @override
  Future<List<Student>> getAllStudents() async {
    final snap = await _db.collection(kStudentsTable).get();
    final list =
        snap.docs.map((d) => Student.fromMap(_withId(d))).toList();
    list.sort((a, b) => a.studentId.compareTo(b.studentId));
    return list;
  }

  @override
  Future<bool> studentIdExists(String studentId) async {
    final snap = await _db
        .collection(kStudentsTable)
        .where('student_id', isEqualTo: studentId.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<String> insertStudent(Student student) async {
    final ref = await _db
        .collection(kStudentsTable)
        .add(_stripId(student.toMap()));
    return ref.id;
  }

  @override
  Future<void> updateStudent(Student student) async {
    await _db
        .collection(kStudentsTable)
        .doc(student.id!)
        .update(_stripId(student.toMap()));
  }

  @override
  Future<void> deleteStudent(String id) async {
    // Resolve the text student_id first so attendance rows can be removed.
    String? studentNo;
    final doc = await _db.collection(kStudentsTable).doc(id).get();
    if (doc.exists) {
      studentNo = (doc.data()?['student_id'] as String?);
    }
    await _db.collection(kStudentsTable).doc(id).delete();
    if (studentNo != null) {
      final att = await _db
          .collection(kAttendanceTable)
          .where('student_id', isEqualTo: studentNo)
          .get();
      final batch = _db.batch();
      for (final d in att.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<int> countStudents() async {
    final agg =
        await _db.collection(kStudentsTable).count().get();
    return agg.count ?? 0;
  }

  // ---------------------------------------------------------------- Courses

  @override
  Future<List<Course>> getAllCourses() async {
    final snap = await _db.collection(kCoursesTable).get();
    final list = snap.docs.map((d) => Course.fromMap(_withId(d))).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<bool> courseNameExists(String courseName) async {
    final snap = await _db
        .collection(kCoursesTable)
        .where('course_name', isEqualTo: courseName.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<String> insertCourse(Course course) async {
    final ref = await _db
        .collection(kCoursesTable)
        .add(_stripId(course.toMap()));
    return ref.id;
  }

  @override
  Future<void> updateCourse(Course course) async {
    await _db
        .collection(kCoursesTable)
        .doc(course.id!)
        .update(_stripId(course.toMap()));
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _db.collection(kCoursesTable).doc(id).delete();
  }

  // ----------------------------------------------------------------- Events

  @override
  Future<AttendanceEvent?> getActiveEvent() async {
    final snap = await _db
        .collection(kEventsTable)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AttendanceEvent.fromMap(_withId(snap.docs.first));
  }

  @override
  Future<List<AttendanceEvent>> getAllEvents() async {
    final snap = await _db.collection(kEventsTable).get();
    final list = snap.docs
        .map((d) => AttendanceEvent.fromMap(_withId(d)))
        .toList();
    list.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<String> insertEvent(
    String name, {
    bool setActive = false,
    String flowType = EventFlowType.oneTime,
  }) async {
    if (setActive) {
      await _deactivateAllEvents();
    }
    final ref = await _db.collection(kEventsTable).add({
      'name': name.trim(),
      'is_active': setActive,
      'flow_type': flowType,
      'created_at': DateTime.now().toIso8601String(),
    });
    return ref.id;
  }

  Future<void> _deactivateAllEvents() async {
    final snap = await _db
        .collection(kEventsTable)
        .where('is_active', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'is_active': false});
    }
    await batch.commit();
  }

  @override
  Future<void> updateEvent(AttendanceEvent event) async {
    await _db.collection(kEventsTable).doc(event.id!).update({
      'name': event.name.trim(),
      'flow_type': event.flowType,
    });
  }

  @override
  Future<void> setActiveEvent(String id) async {
    await _deactivateAllEvents();
    await _db.collection(kEventsTable).doc(id).update({'is_active': true});
  }

  @override
  Future<bool> deleteEvent(String id) async {
    final doc = await _db.collection(kEventsTable).doc(id).get();
    if (!doc.exists) return false;
    if ((doc.data()?['is_active'] as bool? ?? false)) return false;
    await _db.collection(kEventsTable).doc(id).delete();
    return true;
  }

  @override
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

  @override
  Future<Map<String, int>> courseCountsForEvent(String eventId) async {
    final att = await _db
        .collection(kAttendanceTable)
        .where('event_id', isEqualTo: eventId)
        .get();
    if (att.docs.isEmpty) return {};

    final students = await _db.collection(kStudentsTable).get();
    final courseByNo = <String, String>{
      for (final d in students.docs)
        (d.data()['student_id'] as String? ?? ''): (d.data()['course'] as String? ?? ''),
    };

    final Map<String, Set<String>> courseStudents = {};
    for (final d in att.docs) {
      final studentNo = d.data()['student_id']?.toString() ?? '';
      final course = courseByNo[studentNo] ?? '';
      if (course.isEmpty) continue;
      courseStudents.putIfAbsent(course, () => {}).add(studentNo);
    }
    return {
      for (final e in courseStudents.entries) e.key: e.value.length,
    };
  }

  @override
  Future<Map<String, int>> attendanceCountByEvent() async {
    final att = await _db.collection(kAttendanceTable).get();
    final Map<String, Set<String>> eventStudents = {};
    for (final d in att.docs) {
      final eventId = d.data()['event_id']?.toString();
      if (eventId == null || eventId.isEmpty) continue;
      final studentNo = d.data()['student_id']?.toString() ?? '';
      eventStudents.putIfAbsent(eventId, () => {}).add(studentNo);
    }
    return {
      for (final e in eventStudents.entries) e.key: e.value.length,
    };
  }

  // -------------------------------------------------------------- Attendance

  @override
  Future<Attendance?> findAttendance(
    String studentId,
    String date,
    String eventId,
    String checkType,
  ) async {
    final snap = await _db
        .collection(kAttendanceTable)
        .where('student_id', isEqualTo: studentId.trim())
        .where('date', isEqualTo: date)
        .where('event_id', isEqualTo: eventId)
        .where('check_type', isEqualTo: checkType)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Attendance.fromMap(_withId(snap.docs.first));
  }

  @override
  Future<String> insertAttendance(Attendance attendance) async {
    final ref = await _db
        .collection(kAttendanceTable)
        .add(_stripId(attendance.toMap()));
    return ref.id;
  }

  /// Student + event lookup maps for enriching attendance rows.
  Future<_JoinMaps> _joinMaps() async {
    final studentsSnap = await _db.collection(kStudentsTable).get();
    final eventsSnap = await _db.collection(kEventsTable).get();
    final students = <String, Map<String, dynamic>>{
      for (final d in studentsSnap.docs) (d.data()['student_id'] as String? ?? d.id): d.data(),
    };
    final events = <String, String>{
      for (final d in eventsSnap.docs) d.id: (d.data()['name'] as String? ?? ''),
    };
    return _JoinMaps(students, events);
  }

  Attendance _enrich(
    Map<String, dynamic> raw,
    _JoinMaps joins,
  ) {
    final attendance = Attendance.fromMap(raw);
    final studentNo = raw['student_id']?.toString() ?? '';
    final student = joins.students[studentNo];
    final eventId = raw['event_id']?.toString();
    return attendance.copyWith(
      studentName: student == null
          ? null
          : '${student['first_name']} ${student['last_name']}',
      course: student?['course'] as String?,
      yearLevel: student?['year_level'] as String?,
      eventName:
          eventId == null ? null : joins.eventNames[eventId],
    );
  }

  @override
  Future<List<Attendance>> recentAttendance({int limit = 8}) async {
    final snap = await _db.collection(kAttendanceTable).get();
    final raws = snap.docs.map(_withId).toList();
    raws.sort((a, b) {
      final d = (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? '');
      if (d != 0) return d;
      return (b['time'] as String? ?? '').compareTo(a['time'] as String? ?? '');
    });
    final joins = await _joinMaps();
    return raws.take(limit).map((r) => _enrich(r, joins)).toList();
  }

  @override
  Future<List<Attendance>> queryAttendance({
    String? search,
    String? date,
    String? course,
    String? yearLevel,
    String? status,
    String? eventId,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(kAttendanceTable);
    if (date != null && date.isNotEmpty) {
      query = query.where('date', isEqualTo: date);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (eventId != null) {
      query = query.where('event_id', isEqualTo: eventId);
    }
    final snap = await query.get();
    final joins = await _joinMaps();
    var list = snap.docs.map((d) => _enrich(_withId(d), joins)).toList();

    if (course != null && course.isNotEmpty) {
      list = list.where((r) => r.course == course).toList();
    }
    if (yearLevel != null && yearLevel.isNotEmpty) {
      list = list.where((r) => r.yearLevel == yearLevel).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((r) {
        final name = (r.studentName ?? '').toLowerCase();
        final no = r.studentId.toLowerCase();
        return name.contains(q) || no.contains(q);
      }).toList();
    }
    list.sort((a, b) {
      final d = b.date.compareTo(a.date);
      if (d != 0) return d;
      return b.time.compareTo(a.time);
    });
    return list;
  }

  @override
  Future<List<String>> distinctAttendanceDates() async {
    final snap = await _db.collection(kAttendanceTable).get();
    final dates = <String>{};
    for (final d in snap.docs) {
      final date = d.data()['date'] as String?;
      if (date != null) dates.add(date);
    }
    final list = dates.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  @override
  Future<List<Attendance>> attendanceForStudent(String studentId) async {
    final snap = await _db
        .collection(kAttendanceTable)
        .where('student_id', isEqualTo: studentId.trim())
        .get();
    final joins = await _joinMaps();
    final list =
        snap.docs.map((d) => _enrich(_withId(d), joins)).toList();
    list.sort((a, b) {
      final d = b.date.compareTo(a.date);
      if (d != 0) return d;
      return b.time.compareTo(a.time);
    });
    return list;
  }

  @override
  Future<int> countAttendance() async {
    final agg =
        await _db.collection(kAttendanceTable).count().get();
    return agg.count ?? 0;
  }

  @override
  Future<int> countAttendanceOn(String date, {String? eventId}) async {
    Query<Map<String, dynamic>> query = _db
        .collection(kAttendanceTable)
        .where('date', isEqualTo: date);
    if (eventId != null) {
      query = query.where('event_id', isEqualTo: eventId);
    }
    final agg = await query.count().get();
    return agg.count ?? 0;
  }

  // --------------------------------------------------------------- Seed data

  @override
  Future<void> seedDemoData() async {
    // On a fresh device with locked rules and no signed-in user, this read
    // is denied — that just means data already exists server-side, so skip
    // seeding silently instead of crashing startup.
    try {
      final existing =
          await _db.collection(kUsersTable).limit(1).get();
      if (existing.docs.isNotEmpty) return;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      rethrow;
    }

    final adminRef = await _db.collection(kUsersTable).add({
      'username': DemoCredentials.adminUsername,
      'password_hash': kManagedByFirebaseAuth,
      'salt': kManagedByFirebaseAuth,
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });
    await AuthLink.provisionAdmin(
      username: DemoCredentials.adminUsername,
      password: DemoCredentials.adminPassword,
      docId: adminRef.id,
    );

    for (final courseName in kCourses) {
      final exists = await courseNameExists(courseName);
      if (!exists) {
        await _db.collection(kCoursesTable).add({
          'course_name': courseName,
          'created_at': DateTime.now().toIso8601String(),
        });
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
    for (final s in demoStudents) {
      final exists = await studentIdExists(s.$1);
      if (exists) continue;
      final ref = await _db.collection(kStudentsTable).add({
        'student_id': s.$1,
        'last_name': s.$2,
        'first_name': s.$3,
        'course': s.$4,
        'year_level': s.$5,
        'password_hash': kManagedByFirebaseAuth,
        'salt': kManagedByFirebaseAuth,
        'created_at': now.toIso8601String(),
      });
      await AuthLink.provisionStudent(
        studentId: s.$1,
        password: DemoCredentials.studentPassword,
        docId: ref.id,
      );
    }

    final defaultEventId =
        await insertEvent(defaultEventName, setActive: true);

    const history = {
      0: {1: true, 2: true, 4: true},
      1: {1: true, 2: true, 3: true, 4: true},
      2: {1: true, 2: true, 3: true, 5: true},
      3: {2: true, 3: true, 4: true, 5: true},
    };

    for (final entry in history.entries) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: entry.key));
      final recordTime =
          DateTime(day.year, day.month, day.day, 8, 5 + entry.key);
      for (final studentIdx in entry.value.keys) {
        final studentId = '2026-000$studentIdx';
        await _db.collection(kAttendanceTable).add({
          'student_id': studentId,
          'date': Formatters.dbDate(day),
          'time': '${recordTime.hour.toString().padLeft(2, '0')}:'
              '${recordTime.minute.toString().padLeft(2, '0')}',
          'status': AttendanceStatus.present,
          'check_type': CheckType.present,
          'event_id': defaultEventId,
          'created_at': day.toIso8601String(),
        });
      }
    }

    final intramsId = await insertEvent(
      'Intrams',
      setActive: false,
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
        for (final check in intramsCheckTimes.entries) {
          await _db.collection(kAttendanceTable).add({
            'student_id': studentId,
            'date': Formatters.dbDate(day),
            'time': '${check.value.toString().padLeft(2, '0')}:'
                '${(i * 5).toString().padLeft(2, '0')}',
            'status': AttendanceStatus.present,
            'check_type': check.key,
            'event_id': intramsId,
            'created_at': day.toIso8601String(),
          });
        }
      }
    }
  }
}

class _JoinMaps {
  final Map<String, Map<String, dynamic>> students;
  final Map<String, String> eventNames;
  _JoinMaps(this.students, this.eventNames);
}
