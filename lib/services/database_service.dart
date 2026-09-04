import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/attendance_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Local SQLite database (demo-friendly — no server required).
///
/// Tables:
///  - [kUsersTable]: admin accounts
///  - [kStudentsTable]: student records (credentials included for demo login)
///  - [kAttendanceTable]: one record per student per day (UNIQUE constraint
///    prevents duplicate attendance at the database level)
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String dbName = 'attendance_system.db';
  static const String kUsersTable = 'users';
  static const String kStudentsTable = 'students';
  static const String kAttendanceTable = 'attendance';

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
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seed(db);
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

    // One record per student per day → duplicates are impossible at DB level.
    await db.execute('''
      CREATE TABLE $kAttendanceTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PRESENT',
        created_at TEXT NOT NULL,
        UNIQUE (student_id, date),
        FOREIGN KEY (student_id) REFERENCES $kStudentsTable (student_id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_attendance_date ON $kAttendanceTable (date)',
    );
  }

  /// Seeds demo data on first launch so the app is usable immediately:
  /// an admin account, five students, and attendance history for this week.
  Future<void> _seed(Database db) async {
    final adminHash = hashPassword(DemoCredentials.adminPassword, salt: null);
    await db.insert(kUsersTable, {
      'username': DemoCredentials.adminUsername,
      'password_hash': adminHash['hash'],
      'salt': adminHash['salt'],
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

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
          'created_at': day.toIso8601String(),
        });
      }
    });
  }

  /// Returns a random salt + SHA-256 hash of salt+password.
  static Map<String, String> hashPassword(
    String password, {
    String? salt,
  }) {
    final effectiveSalt = salt ?? _randomSalt();
    final hash = sha256.convert('$effectiveSalt:$password'.codeUnits);
    return {'salt': effectiveSalt, 'hash': hash.toString()};
  }

  static String _randomSalt() {
    final random = DateTime.now().microsecondsSinceEpoch;
    return '$random-${sha256.convert('$random'.codeUnits)}'
        .substring(0, 16);
  }

  /// Verifies a plain-text password against a stored hash + salt.
  static bool verifyPassword(String password, String salt, String hash) {
    final candidate = sha256.convert('$salt:$password'.codeUnits).toString();
    return candidate == hash;
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

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return db.insert(kStudentsTable, student.toMap());
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return db.update(
      kStudentsTable,
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    // Attendance rows cascade-delete via FK.
    return db.delete(kStudentsTable, where: 'id = ?', whereArgs: [id]);
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

  Future<int> countAttendanceOn(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $kAttendanceTable WHERE date = ?',
      [date],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Existing attendance record for a student on a given date, if any.
  Future<Attendance?> findAttendance(String studentId, String date) async {
    final db = await database;
    final rows = await db.query(
      kAttendanceTable,
      where: 'student_id = ? AND date = ?',
      whereArgs: [studentId, date],
      limit: 1,
    );
    return rows.isEmpty ? null : Attendance.fromMap(rows.first);
  }

  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    return db.insert(kAttendanceTable, attendance.toMap());
  }

  /// Recent attendance joined with student names, newest first.
  Future<List<Attendance>> recentAttendance({int limit = 8}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*,
             s.first_name || ' ' || s.last_name AS full_name,
             s.course,
             s.year_level
      FROM $kAttendanceTable a
      JOIN $kStudentsTable s ON s.student_id = a.student_id
      ORDER BY a.date DESC, a.time DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(Attendance.fromMap).toList();
  }

  /// All attendance records joined with student names, newest first,
  /// optionally filtered by search text, date, course, year level and status.
  Future<List<Attendance>> queryAttendance({
    String? search,
    String? date,
    String? course,
    String? yearLevel,
    String? status,
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

    final sql = '''
      SELECT a.*,
             s.first_name || ' ' || s.last_name AS full_name,
             s.course,
             s.year_level
      FROM $kAttendanceTable a
      JOIN $kStudentsTable s ON s.student_id = a.student_id
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

  /// A student's own attendance history, newest first.
  Future<List<Attendance>> attendanceForStudent(String studentId) async {
    final db = await database;
    final rows = await db.query(
      kAttendanceTable,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC, time DESC',
    );
    return rows.map(Attendance.fromMap).toList();
  }
}