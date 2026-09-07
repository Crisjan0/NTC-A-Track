import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/attendance_model.dart';
import '../models/event_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/password_hash.dart';
import 'database_service_interface.dart';

/// Local SQLite database (demo-friendly — no server required).
///
/// Tables:
///  - [kUsersTable]: admin accounts
///  - [kStudentsTable]: student records (credentials included for demo login)
///  - [kEventsTable]: attendance events (e.g. "Intrams"); exactly one is
///    active at a time and QR scans are recorded to it
///  - [kAttendanceTable]: one record per student per day per event (UNIQUE
///    constraint prevents duplicate attendance at the database level)
class DatabaseService implements DatabaseServiceInterface {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String dbName = 'attendance_system.db';
  static const String kUsersTable = 'users';
  static const String kStudentsTable = 'students';
  static const String kEventsTable = 'events';
  static const String kAttendanceTable = 'attendance';

  /// Default event used on first launch and as a fallback when the admin
  /// has not created (and activated) their own event yet.
  static const String defaultEventName = 'General Attendance';

  Database? _db;

  /// Test-only override that makes the service open a fresh (e.g. in-memory)
  /// database instead of the on-device file.
  @visibleForTesting
  static String? overrideDatabasePath;

  /// Test-only: closes and forgets the cached connection so the next access
  /// re-opens (and re-seeds) the database.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    final db = instance._db;
    instance._db = null;
    await db?.close();
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = overrideDatabasePath ??
        p.join(await getDatabasesPath(), dbName);
    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateToV4(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $kUsersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'admin',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $kStudentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL UNIQUE,
        last_name TEXT NOT NULL,
        first_name TEXT NOT NULL,
        course TEXT NOT NULL,
        year_level TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createCoursesTable(db);
    await _createEventsTable(db);
    await _createAttendanceTable(db);

    await db.execute(
      'CREATE INDEX idx_attendance_date ON $kAttendanceTable (date)',
    );
  }

  Future<void> _createCoursesTable(Database db) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $kEventsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        flow_type TEXT NOT NULL DEFAULT 'ONE_TIME',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // One record per student per day per event per check type → duplicates are
  // impossible at DB level, while a student can still attend several events
  // in a day and scan Time In / Time Out for AM/PM events.
  Future<void> _createAttendanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE $kAttendanceTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PRESENT',
        check_type TEXT NOT NULL DEFAULT 'PRESENT',
        event_id INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE (student_id, date, event_id, check_type),
        FOREIGN KEY (student_id) REFERENCES $kStudentsTable (student_id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES $kEventsTable (id) ON DELETE SET NULL
      )
    ''');
  }

  /// v1 → v2: adds the events table, tags existing attendance with a default
  /// event, and widens the unique constraint so attendance is unique per
  /// student per day *per event*.
  Future<void> _migrateToV2(Database db) async {
    await _createEventsTable(db);
    final defaultEventId =
        await _insertEvent(db, name: defaultEventName, isActive: true);

    // SQLite cannot alter a UNIQUE constraint, so rebuild the table.
    await db.execute(
      'ALTER TABLE $kAttendanceTable ADD COLUMN event_id INTEGER',
    );

    await db.execute('''
      CREATE TABLE ${kAttendanceTable}_v2 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PRESENT',
        event_id INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE (student_id, date, event_id),
        FOREIGN KEY (student_id) REFERENCES $kStudentsTable (student_id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES $kEventsTable (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      INSERT INTO ${kAttendanceTable}_v2
        (id, student_id, date, time, status, event_id, created_at)
      SELECT id, student_id, date, time, status, ?, created_at
      FROM $kAttendanceTable
    ''', [defaultEventId]);
    await db.execute('DROP TABLE $kAttendanceTable');
    await db.execute(
      'ALTER TABLE ${kAttendanceTable}_v2 RENAME TO $kAttendanceTable',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_date ON $kAttendanceTable (date)',
    );
  }

  /// v2 → v3: adds the attendance flow type to events (ONE_TIME by default)
  /// and widens the unique constraint to one record per student per day per
  /// event per check type, so Time In / Time Out events can store AM/PM
  /// check-ins and check-outs.
  Future<void> _migrateToV3(Database db) async {
    await db.execute(
      'ALTER TABLE $kEventsTable ADD COLUMN flow_type '
      "TEXT NOT NULL DEFAULT 'ONE_TIME'",
    );

    // SQLite cannot alter a UNIQUE constraint, so rebuild the table.
    await db.execute(
      'ALTER TABLE $kAttendanceTable ADD COLUMN check_type '
      "TEXT NOT NULL DEFAULT 'PRESENT'",
    );
    await db.execute('''
      CREATE TABLE ${kAttendanceTable}_v3 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PRESENT',
        check_type TEXT NOT NULL DEFAULT 'PRESENT',
        event_id INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE (student_id, date, event_id, check_type),
        FOREIGN KEY (student_id) REFERENCES $kStudentsTable (student_id) ON DELETE CASCADE,
        FOREIGN KEY (event_id) REFERENCES $kEventsTable (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      INSERT INTO ${kAttendanceTable}_v3
        (id, student_id, date, time, status, check_type, event_id, created_at)
      SELECT id, student_id, date, time, status, 'PRESENT', event_id, created_at
      FROM $kAttendanceTable
    ''');
    await db.execute('DROP TABLE $kAttendanceTable');
    await db.execute(
      'ALTER TABLE ${kAttendanceTable}_v3 RENAME TO $kAttendanceTable',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_date ON $kAttendanceTable (date)',
    );
  }

  /// v3 -> v4: add courses table if it does not exist.
  Future<void> _migrateToV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Seeds demo data on first launch so the app is usable immediately:
  /// an admin account, default courses, five students, a default active event, and
  /// attendance history for this week.
  Future<void> _seed(Database db) async {
    final adminHash = hashPassword(DemoCredentials.adminPassword, salt: null);
    await db.insert(kUsersTable, {
      'username': DemoCredentials.adminUsername,
      'password_hash': adminHash['hash'],
      'salt': adminHash['salt'],
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed default courses (idempotent via UNIQUE constraint).
    for (final courseName in kCourses) {
      try {
        await db.insert('courses', {
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
    for (final s in demoStudents) {
      final creds = hashPassword(DemoCredentials.studentPassword, salt: null);
      await db.insert(kStudentsTable, {
        'student_id': s.$1,
        'last_name': s.$2,
        'first_name': s.$3,
        'course': s.$4,
        'year_level': s.$5,
        'password_hash': creds['hash'],
        'salt': creds['salt'],
        'created_at': now.toIso8601String(),
      });
    }

    // Every seeded record belongs to the default (active) event.
    final defaultEventId =
        await _insertEvent(db, name: defaultEventName, isActive: true);

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
        db.insert(kAttendanceTable, {
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
    });

    // Demo Time In/Out event so the AM/PM flow is visible right away on
    // fresh installs. Two students with a full AM/PM in/out day today and
    // yesterday, tagged to a non-active "Intrams" event.
    final intramsId = await _insertEvent(
      db,
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
        intramsCheckTimes.forEach((checkType, hour) {
          db.insert(kAttendanceTable, {
            'student_id': intramsStudents[i],
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

  // ---------------------------------------------------------------- queries

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final rows = await db.query(
      kUsersTable,
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  /// All admin accounts, newest first.
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final rows = await db.query(
      kUsersTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(User.fromMap).toList();
  }

  /// Inserts a new admin user. Returns the new user's ID.
  Future<String> insertUser(User user) async {
    final db = await database;
    final id = await db.insert(kUsersTable, user.toMap());
    return id.toString();
  }

  /// Update an existing admin's password. Returns the new salt + hash map so
  /// callers can also update their own in-memory copy.
  Future<Map<String, String>> updateUserPassword(
    String userId,
    String plainPassword,
  ) async {
    final creds = hashPassword(plainPassword);
    await database.then((db) => db.update(
      kUsersTable,
      {
        'password_hash': creds['hash'],
        'salt': creds['salt'],
      },
      where: 'id = ?',
      whereArgs: [int.parse(userId)],
    ));
    return creds;
  }

  /// Update an existing admin account's metadata (username and/or role).
  /// Usernames are unique, so a collision with another account is rejected.
  Future<bool> updateUser(
    User user,
    {String? newUsername,
    String? newRole,
  }) async {
    final db = await database;
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      final collision = await db.query(
        kUsersTable,
        columns: ['id'],
        where: 'username = ? AND id != ?',
        whereArgs: [newUsername.trim(), user.id],
        limit: 1,
      );
      if (collision.isNotEmpty) return false;
    }

    await db.update(
      kUsersTable,
      {
        if (newUsername != null && newUsername.trim().isNotEmpty)
          'username': newUsername.trim(),
        if (newRole != null && newRole.trim().isNotEmpty)
          'role': newRole.trim(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return true;
  }

  /// Deletes an admin account. The caller is responsible for preventing an
  /// admin from deleting their own account (caller supplies [currentUserId]).
  Future<bool> deleteUser(String userId, {String? currentUserId}) async {
    if (currentUserId == userId) return false;
    final db = await database;
    final rows = await db.query(
      kUsersTable,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [int.parse(userId)],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    await db.delete(kUsersTable, where: 'id = ?', whereArgs: [int.parse(userId)]);
    return true;
  }

  Future<Student?> getStudentById(String studentId) async {
    final db = await database;
    final rows = await db.query(
      kStudentsTable,
      where: 'student_id = ?',
      whereArgs: [studentId.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final rows = await db.query(
      kStudentsTable,
      orderBy: 'student_id ASC',
    );
    return rows.map(Student.fromMap).toList();
  }

  Future<bool> studentIdExists(String studentId) async {
    final db = await database;
    final rows = await db.query(
      kStudentsTable,
      columns: ['student_id'],
      where: 'student_id = ?',
      whereArgs: [studentId.trim()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String> insertStudent(Student student) async {
    final db = await database;
    final id = await db.insert(kStudentsTable, student.toMap());
    return id.toString();
  }

  Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      kStudentsTable,
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> deleteStudent(String id) async {
    final db = await database;
    // Attendance rows cascade-delete via FK.
    await db.delete(kStudentsTable, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  Future<int> countStudents() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $kStudentsTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAttendance() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM $kAttendanceTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Distinct students with a record on [date], optionally scoped to a
  /// single [eventId]. DISTINCT matters for Time In/Out events where one
  /// student produces several records per day. Scoping to the active event
  /// is what makes "Present Today" agree with the event being scanned for.
  Future<int> countAttendanceOn(String date, {String? eventId}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT student_id) AS c FROM $kAttendanceTable '
      'WHERE date = ?${eventId == null ? '' : ' AND event_id = ?'}',
      [date, if (eventId != null) int.parse(eventId)],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --------------------------------------------------------------- events

  /// The single event QR scans currently record to, if any.
  Future<AttendanceEvent?> getActiveEvent() async {
    final db = await database;
    final rows = await db.query(
      kEventsTable,
      where: 'is_active = 1',
      limit: 1,
    );
    return rows.isEmpty ? null : AttendanceEvent.fromMap(rows.first);
  }

  Future<List<AttendanceEvent>> getAllEvents() async {
    final db = await database;
    final rows = await db.query(
      kEventsTable,
      orderBy: 'is_active DESC, created_at ASC',
    );
    return rows.map(AttendanceEvent.fromMap).toList();
  }

  /// Creates an event, optionally activating it right away.
  Future<String> insertEvent(
    String name, {
    bool setActive = false,
    String flowType = EventFlowType.oneTime,
  }) async {
    final db = await database;
    final id = await _insertEvent(
      db,
      name: name,
      isActive: setActive,
      flowType: flowType,
    );
    return id.toString();
  }

  /// Updates an event's name / flow type.
  Future<void> updateEvent(AttendanceEvent event) async {
    final db = await database;
    await db.update(
      kEventsTable,
      {
        'name': event.name.trim(),
        'flow_type': event.flowType,
      },
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Makes [id] the active event (all others become inactive).
  Future<void> setActiveEvent(String id) async {
    final db = await database;
    await _setActive(db, int.parse(id));
  }

  /// Deletes a non-active event. Its attendance rows are kept but lose the
  /// event tag (FK ON DELETE SET NULL). Returns false if the event is
  /// currently active, so the active event can never be removed.
  Future<bool> deleteEvent(String id) async {
    final db = await database;
    final rows = await db.query(
      kEventsTable,
      columns: ['is_active'],
      where: 'id = ?',
      whereArgs: [int.parse(id)],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    if ((rows.first['is_active'] as int?) == 1) return false;
    await db.delete(kEventsTable, where: 'id = ?', whereArgs: [int.parse(id)]);
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
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.course, COUNT(DISTINCT a.student_id) AS c
      FROM $kAttendanceTable a
      JOIN $kStudentsTable s ON s.student_id = a.student_id
      WHERE a.event_id = ?
      GROUP BY s.course
      ORDER BY c DESC, s.course ASC
    ''', [int.parse(eventId)]);
    return {
      for (final r in rows) r['course'] as String: (r['c'] as num).toInt(),
    };
  }

  /// Distinct-student attendance count per event, keyed by event id.
  Future<Map<String, int>> attendanceCountByEvent() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT event_id, COUNT(DISTINCT student_id) AS c '
      'FROM $kAttendanceTable '
      'WHERE event_id IS NOT NULL GROUP BY event_id',
    );
    return {
      for (final r in rows)
        if (r['event_id'] is int) r['event_id'].toString(): (r['c'] as num).toInt(),
    };
  }

  Future<int> _insertEvent(
    Database db, {
    required String name,
    bool isActive = false,
    String flowType = EventFlowType.oneTime,
  }) async {
    final id = await db.insert(kEventsTable, {
      'name': name.trim(),
      'is_active': 0,
      'flow_type': flowType,
      'created_at': DateTime.now().toIso8601String(),
    });
    if (isActive) {
      await _setActive(db, id);
    }
    return id;
  }

  Future<void> _setActive(Database db, int id) async {
    await db.rawUpdate('UPDATE $kEventsTable SET is_active = 0');
    await db.update(
      kEventsTable,
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ----------------------------------------------------------- courses

  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final rows = await db.query(
      'courses',
      orderBy: 'course_name ASC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<bool> courseNameExists(String courseName) async {
    final db = await database;
    final rows = await db.query(
      'courses',
      columns: ['id'],
      where: 'course_name = ?',
      whereArgs: [courseName.trim()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String> insertCourse(Course course) async {
    final db = await database;
    final id = await db.insert('courses', course.toMap());
    return id.toString();
  }

  Future<void> updateCourse(Course course) async {
    final db = await database;
    await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<void> deleteCourse(String id) async {
    final db = await database;
    await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  // ----------------------------------------------------------- attendance

  /// Existing record for a student on a given date, event and check type.
  Future<Attendance?> findAttendance(
    String studentId,
    String date,
    String eventId,
    String checkType,
  ) async {
    final db = await database;
    final rows = await db.query(
      kAttendanceTable,
      where: 'student_id = ? AND date = ? AND event_id = ? AND check_type = ?',
      whereArgs: [studentId, date, int.parse(eventId), checkType],
      limit: 1,
    );
    return rows.isEmpty ? null : Attendance.fromMap(rows.first);
  }

  Future<String> insertAttendance(Attendance attendance) async {
    final db = await database;
    final id = await db.insert(kAttendanceTable, attendance.toMap());
    return id.toString();
  }

  /// Recent attendance joined with student + event names, newest first.
  Future<List<Attendance>> recentAttendance({int limit = 8}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*,
             s.first_name || ' ' || s.last_name AS full_name,
             s.course,
             s.year_level,
             e.name AS event_name
      FROM $kAttendanceTable a
      JOIN $kStudentsTable s ON s.student_id = a.student_id
      LEFT JOIN $kEventsTable e ON e.id = a.event_id
      ORDER BY a.date DESC, a.time DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(Attendance.fromMap).toList();
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
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim()}%';
      where.add(
        '(a.student_id LIKE ? OR s.first_name LIKE ? OR s.last_name LIKE ?)',
      );
      args.addAll([q, q, q]);
    }
    if (date != null && date.isNotEmpty) {
      where.add('a.date = ?');
      args.add(date);
    }
    if (course != null && course.isNotEmpty) {
      where.add('s.course = ?');
      args.add(course);
    }
    if (yearLevel != null && yearLevel.isNotEmpty) {
      where.add('s.year_level = ?');
      args.add(yearLevel);
    }
    if (status != null && status.isNotEmpty) {
      where.add('a.status = ?');
      args.add(status);
    }
    if (eventId != null) {
      where.add('a.event_id = ?');
      args.add(int.parse(eventId));
    }

    final sql = '''
      SELECT a.*,
             s.first_name || ' ' || s.last_name AS full_name,
             s.course,
             s.year_level,
             e.name AS event_name
      FROM $kAttendanceTable a
      JOIN $kStudentsTable s ON s.student_id = a.student_id
      LEFT JOIN $kEventsTable e ON e.id = a.event_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY a.date DESC, a.time DESC
    ''';

    final rows = await db.rawQuery(sql, args);
    return rows.map(Attendance.fromMap).toList();
  }

  /// All distinct dates that have any attendance record (i.e. "school days").
  Future<List<String>> distinctAttendanceDates() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date FROM $kAttendanceTable ORDER BY date DESC',
    );
    return rows.map((r) => r['date'] as String).toList();
  }

  /// A student's own attendance history, newest first, with event names.
  Future<List<Attendance>> attendanceForStudent(String studentId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*,
             e.name AS event_name
      FROM $kAttendanceTable a
      LEFT JOIN $kEventsTable e ON e.id = a.event_id
      WHERE a.student_id = ?
      ORDER BY a.date DESC, a.time DESC
    ''', [studentId]);
    return rows.map(Attendance.fromMap).toList();
  }

  /// Seeds demo data on first launch so the app is usable immediately.
  @override
  Future<void> seedDemoData() async {
    final db = await database;
    final existing = await db.query(kUsersTable, limit: 1);
    if (existing.isNotEmpty) return;

    final adminHash = hashPassword(DemoCredentials.adminPassword, salt: null);
    await db.insert(kUsersTable, {
      'username': DemoCredentials.adminUsername,
      'password_hash': adminHash['hash'],
      'salt': adminHash['salt'],
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    for (final courseName in kCourses) {
      try {
        await db.insert('courses', {
          'course_name': courseName,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
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
      final creds = hashPassword(DemoCredentials.studentPassword, salt: null);
      await db.insert(kStudentsTable, {
        'student_id': s.$1,
        'last_name': s.$2,
        'first_name': s.$3,
        'course': s.$4,
        'year_level': s.$5,
        'password_hash': creds['hash'],
        'salt': creds['salt'],
        'created_at': now.toIso8601String(),
      });
    }

    final defaultEventId = await _insertEvent(db, name: defaultEventName, isActive: true);

    const history = {
      0: {1: true, 2: true, 4: true},
      1: {1: true, 2: true, 3: true, 4: true},
      2: {1: true, 2: true, 3: true, 5: true},
      3: {2: true, 3: true, 4: true, 5: true},
    };

    history.forEach((offset, present) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: offset));
      final recordTime = DateTime(day.year, day.month, day.day, 8, 5 + offset);
      for (final studentIdx in present.keys) {
        final studentId = '2026-000$studentIdx';
        db.insert(kAttendanceTable, {
          'student_id': studentId,
          'date': Formatters.dbDate(day),
          'time': '${recordTime.hour.toString().padLeft(2, '0')}:${recordTime.minute.toString().padLeft(2, '0')}',
          'status': AttendanceStatus.present,
          'check_type': CheckType.present,
          'event_id': defaultEventId,
          'created_at': day.toIso8601String(),
        });
      }
    });

    final intramsId = await _insertEvent(db, name: 'Intrams', isActive: false, flowType: EventFlowType.timeInOut);
    const intramsStudents = ['2026-0002', '2026-0004'];
    const intramsCheckTimes = {
      CheckType.amIn: 8,
      CheckType.amOut: 12,
      CheckType.pmIn: 13,
      CheckType.pmOut: 17,
    };
    for (final offset in [0, 1]) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: offset));
      for (var i = 0; i < intramsStudents.length; i++) {
        final studentId = intramsStudents[i];
        intramsCheckTimes.forEach((checkType, hour) {
          db.insert(kAttendanceTable, {
            'student_id': studentId,
            'date': Formatters.dbDate(day),
            'time': '${hour.toString().padLeft(2, '0')}:${(i * 5).toString().padLeft(2, '0')}',
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