import 'package:attendancesystem/services/attendance_service.dart';
import 'package:attendancesystem/services/auth_service.dart';
import 'package:attendancesystem/services/database_service.dart';
import 'package:attendancesystem/services/session_service.dart';
import 'package:attendancesystem/services/student_service.dart';
import 'package:attendancesystem/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    // Fresh in-memory database (re-seeded) for every test.
    DatabaseService.overrideDatabasePath = inMemoryDatabasePath;
    await DatabaseService.resetForTesting();
    SessionService.instance.clear();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  group('Seed data', () {
    test('admin can log in with seeded credentials', () async {
      final session = await AuthService.instance.loginAdmin(
        DemoCredentials.adminUsername,
        DemoCredentials.adminPassword,
      );
      expect(session.isAdmin, isTrue);
      expect(session.username, DemoCredentials.adminUsername);
    });

    test('students can log in with seeded credentials', () async {
      final session = await AuthService.instance.loginStudent(
        '2026-0001',
        DemoCredentials.studentPassword,
      );
      expect(session.isStudent, isTrue);
      expect(session.studentId, '2026-0001');
    });

    test('wrong password is rejected', () async {
      expect(
        () => AuthService.instance.loginAdmin('admin', 'wrong-pass'),
        throwsA(isA<AuthException>()),
      );
    });

    test('unknown student ID is rejected', () async {
      expect(
        () => AuthService.instance.loginStudent('9999-9999', 'x'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('Student management', () {
    test('adds a student with a unique ID', () async {
      await StudentService.instance.addStudent(
        studentId: '2026-0100',
        lastName: 'Test',
        firstName: 'User',
        course: kCourses.first,
        yearLevel: kYearLevels.first,
        password: 'secret123',
      );
      final student =
          await StudentService.instance.getByStudentId('2026-0100');
      expect(student, isNotNull);
      expect(student!.fullName, 'User Test');

      // The new student can log in with their own password.
      final session =
          await AuthService.instance.loginStudent('2026-0100', 'secret123');
      expect(session.isStudent, isTrue);
    });

    test('rejects duplicate student IDs', () async {
      expect(
        () => StudentService.instance.addStudent(
          studentId: '2026-0001',
          lastName: 'Dup',
          firstName: 'Dupe',
          course: kCourses.first,
          yearLevel: kYearLevels.first,
          password: 'secret123',
        ),
        throwsA(isA<StudentException>()),
      );
    });

    test('searches and filters students', () async {
      final all = await StudentService.instance.searchAndFilter();
      expect(all.length, 5);

      final juan = await StudentService.instance
          .searchAndFilter(search: '2026-0001');
      expect(juan.length, 1);
      expect(juan.first.firstName, 'Juan');

      final bsit = await StudentService.instance
          .searchAndFilter(course: kCourses[0]);
      expect(bsit.length, 2);

      final secondYear = await StudentService.instance
          .searchAndFilter(yearLevel: kYearLevels[1]);
      expect(secondYear.length, 2);
    });

    test('deletes a student and their attendance', () async {
      final juan = (await StudentService.instance.getByStudentId('2026-0001'))!;
      await StudentService.instance.deleteStudent(juan);

      expect(
        await StudentService.instance.getByStudentId('2026-0001'),
        isNull,
      );
      // Their PRESENT records are gone (only synthetic ABSENT placeholders
      // remain for school days recorded by other students).
      final history =
          await AttendanceService.instance.studentHistory('2026-0001');
      expect(
        history.where((r) => r.status == AttendanceStatus.present),
        isEmpty,
      );
    });
  });

  group('Attendance flow', () {
    test('scan records attendance once, then reports duplicate', () async {
      // 2026-0003 is seeded as ABSENT today, so the first scan succeeds.
      final first =
          await AttendanceService.instance.recordFromScan('2026-0003');
      expect(first.type, AttendanceResultType.success);
      expect(first.student!.fullName, 'Jose Reyes');
      expect(first.attendance!.status, AttendanceStatus.present);

      // The second scan on the same day must be blocked.
      final second =
          await AttendanceService.instance.recordFromScan('2026-0003');
      expect(second.type, AttendanceResultType.alreadyRecorded);
    });

    test('unknown QR payload reports student not found', () async {
      final result =
          await AttendanceService.instance.recordFromScan('9999-9999');
      expect(result.type, AttendanceResultType.studentNotFound);
    });

    test('dashboard stats match seeded data', () async {
      final stats = await AttendanceService.instance.dashboardStats();
      expect(stats.totalStudents, 5);
      expect(stats.presentToday, 3);
      expect(stats.absentToday, 2);
      expect(stats.totalAttendance, greaterThan(0));
    });

    test('student summary computes rate', () async {
      final summary =
          await AttendanceService.instance.studentSummary('2026-0001');
      // 2026-0001 attended 3 of the 4 seeded school days.
      expect(summary.present, 3);
      expect(summary.absent, 1);
      expect(summary.rate, closeTo(75.0, 0.01));
    });

    test('student history lists absent days too', () async {
      final history =
          await AttendanceService.instance.studentHistory('2026-0005');
      // 2026-0005 missed today and yesterday; attended the other two days.
      final absent =
          history.where((r) => r.status == AttendanceStatus.absent);
      expect(absent.length, 2);
    });

    test('filtering attendance by course and date works', () async {
      final filtered = await AttendanceService.instance.queryAttendance(
        course: kCourses[0], // BS Information Technology
      );
      expect(filtered, isNotEmpty);
      expect(
        filtered.every((r) => r.course == kCourses[0]),
        isTrue,
      );
    });
  });

  group('Events', () {
    test('a default event is seeded and active', () async {
      final active = await AttendanceService.instance.activeEvent();
      expect(active.name, DatabaseService.defaultEventName);
      expect(active.isActive, isTrue);

      final all = await AttendanceService.instance.allEvents();
      expect(all.length, 1);
    });

    test('scans are recorded to the active event', () async {
      final intramsId =
          await AttendanceService.instance.createEvent('Intrams');
      await AttendanceService.instance.setActiveEvent(intramsId);

      final result =
          await AttendanceService.instance.recordFromScan('2026-0003');
      expect(result.type, AttendanceResultType.success);
      expect(result.eventName, 'Intrams');
      expect(result.attendance!.eventId, intramsId);
    });

    test('same student can attend two events in one day', () async {
      // General Attendance (default, active) — 2026-0003 was absent today.
      final first =
          await AttendanceService.instance.recordFromScan('2026-0003');
      expect(first.type, AttendanceResultType.success);
      expect(first.eventName, DatabaseService.defaultEventName);

      // A second scan for the same event is a duplicate.
      final dup =
          await AttendanceService.instance.recordFromScan('2026-0003');
      expect(dup.type, AttendanceResultType.alreadyRecorded);

      // Switching the active event allows a second record the same day.
      final intramsId =
          await AttendanceService.instance.createEvent('Intrams');
      await AttendanceService.instance.setActiveEvent(intramsId);
      final second =
          await AttendanceService.instance.recordFromScan('2026-0003');
      expect(second.type, AttendanceResultType.success);
      expect(second.eventName, 'Intrams');
    });

    test('the active event cannot be deleted', () async {
      final active = await AttendanceService.instance.activeEvent();
      expect(await AttendanceService.instance.deleteEvent(active.id!), isFalse);

      final id =
          await AttendanceService.instance.createEvent('Foundation Day');
      await AttendanceService.instance.setActiveEvent(id);
      expect(await AttendanceService.instance.deleteEvent(id), isFalse);

      final other =
          await AttendanceService.instance.createEvent('Flag Ceremony');
      expect(await AttendanceService.instance.deleteEvent(other), isTrue);
    });

    test('attendance can be filtered by event', () async {
      final defaultId = (await AttendanceService.instance.activeEvent()).id!;

      final intramsId =
          await AttendanceService.instance.createEvent('Intrams');
      await AttendanceService.instance.setActiveEvent(intramsId);
      await AttendanceService.instance.recordFromScan('2026-0003');

      final intramsRecords = await AttendanceService.instance
          .queryAttendance(eventId: intramsId);
      expect(intramsRecords, hasLength(1));
      expect(intramsRecords.first.eventName, 'Intrams');
      expect(intramsRecords.first.eventId, intramsId);

      final generalRecords =
          await AttendanceService.instance.queryAttendance(eventId: defaultId);
      expect(generalRecords, isNotEmpty);
      expect(
        generalRecords.every((r) => r.eventId == defaultId),
        isTrue,
      );
    });
  });
}