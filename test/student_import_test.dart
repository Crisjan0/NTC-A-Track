import 'package:attendancesystem/services/auth_service.dart';
import 'package:attendancesystem/services/database_service.dart';
import 'package:attendancesystem/services/session_service.dart';
import 'package:attendancesystem/services/student_service.dart';
import 'package:attendancesystem/utils/constants.dart';
import 'package:attendancesystem/utils/student_csv.dart';
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
    DatabaseService.overrideDatabasePath = inMemoryDatabasePath;
    await DatabaseService.resetForTesting();
    SessionService.instance.clear();
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  group('parseStudentCsv', () {
    test('parses rows with a canonical header row', () {
      final rows = parseStudentCsv(
        'Student ID,First Name,Last Name,Course,Year Level\n'
        '2026-0100,Juan,Dela Cruz,BS Information Technology,1st Year\n'
        '2026-0101,Maria,Santos,BS Nursing,2nd Year\n',
      );
      expect(rows, hasLength(2));
      expect(rows[0].studentId, '2026-0100');
      expect(rows[0].firstName, 'Juan');
      expect(rows[0].lastName, 'Dela Cruz');
      expect(rows[0].course, 'BS Information Technology');
      expect(rows[0].yearLevel, '1st Year');
      expect(rows[1].studentId, '2026-0101');
      expect(rows[1].fullName, 'Maria Santos');
    });

    test('matches common header synonyms regardless of order', () {
      final rows = parseStudentCsv(
        'Student No,Program,Year,Surname,Given Name\n'
        '2026-0200,BS Computer Science,3rd Year,Reyes,Jose\n',
      );
      expect(rows, hasLength(1));
      expect(rows[0].studentId, '2026-0200');
      expect(rows[0].firstName, 'Jose');
      expect(rows[0].lastName, 'Reyes');
      expect(rows[0].course, 'BS Computer Science');
      expect(rows[0].yearLevel, '3rd Year');
    });

    test('falls back to fixed column order when there is no header', () {
      final rows = parseStudentCsv(
        '2026-0300,Juan,Dela Cruz,BSIT,1st Year\n'
        '2026-0301,Maria,Santos,BSN,2nd Year',
      );
      expect(rows, hasLength(2));
      expect(rows[0].studentId, '2026-0300');
      expect(rows[0].fullName, 'Juan Dela Cruz');
      expect(rows[1].course, 'BSN');
      expect(rows[1].yearLevel, '2nd Year');
    });

    test('handles quoted fields, commas and CRLF line endings', () {
      final rows = parseStudentCsv(
        'Student ID,First Name,Last Name,Course,Year Level\r\n'
        '"2026-0400","Juan, Jr.","Dela Cruz","BS IT, Specialized","1st Year"\r\n'
        '"2026-0401","Maria ""May""","Santos","BS Nursing","2nd Year"\r\n',
      );
      expect(rows, hasLength(2));
      expect(rows[0].firstName, 'Juan, Jr.');
      expect(rows[0].course, 'BS IT, Specialized');
      expect(rows[1].firstName, 'Maria "May"');
    });

    test('strips a UTF-8 BOM before parsing', () {
      final rows = parseStudentCsv(
        '\uFEFFStudent ID,First Name,Last Name,Course,Year Level\n'
        '2026-0500,Juan,Dela Cruz,BSIT,1st Year\n',
      );
      expect(rows, hasLength(1));
      expect(rows[0].studentId, '2026-0500');
    });

    test('returns no rows for an empty file', () {
      expect(parseStudentCsv(''), isEmpty);
      expect(parseStudentCsv('\n\n'), isEmpty);
    });

    test('the downloadable template parses back into one example row', () {
      final template = buildStudentCsvTemplate();
      expect(template, startsWith('\uFEFF'));
      final rows = parseStudentCsv(template);
      expect(rows, hasLength(1));
      expect(rows.first.studentId, '2026-0100');
      expect(rows.first.fullName, 'Juan Dela Cruz');
      expect(rows.first.course, 'BS Information Technology');
      expect(rows.first.yearLevel, '1st Year');
    });
  });

  group('importStudents', () {
    test('imported students get the default password', () async {
      final rows = parseStudentCsv(
        '2026-0100,Juan,Dela Cruz,BS Information Technology,1st Year\n'
        '2026-0101,Maria,Santos,BS Nursing,2nd Year',
      );
      final result = await StudentService.instance.importStudents(rows);
      expect(result.imported, 2);
      expect(result.skippedCount, 0);

      // The new students can log in with the shared default password.
      final session = await AuthService.instance
          .loginStudent('2026-0100', kDefaultStudentPassword);
      expect(session.isStudent, isTrue);
      expect(session.studentId, '2026-0100');

      expect(
        () => AuthService.instance.loginStudent('2026-0101', 'wrong-pass'),
        throwsA(isA<AuthException>()),
      );

      final maria =
          await StudentService.instance.getByStudentId('2026-0101');
      expect(maria, isNotNull);
      expect(maria!.fullName, 'Maria Santos');
    });

    test('skips IDs already in the database and duplicates in the file',
        () async {
      final rows = parseStudentCsv(
        '2026-0001,Juan,Dela Cruz,BSIT,1st Year\n' // seeded → skip
        '2026-9999,New,Kid,BSCS,3rd Year\n' // imported
        '2026-9999,Other,Kid,BSCS,4th Year\n', // duplicate in file → skip
      );
      final result = await StudentService.instance.importStudents(rows);
      expect(result.imported, 1);
      expect(result.skippedCount, 2);
      expect(result.skippedReasons, contains('Already in the database'));
      expect(result.skippedReasons, contains('Duplicate within the file'));
    });

    test('skips rows with missing required fields', () async {
      final rows = parseStudentCsv(
        '2026-0200,Juan,,BSIT,1st Year\n' // no last name
        '2026-0201,Maria,Santos,BSN,2nd Year\n', // valid
      );
      final result = await StudentService.instance.importStudents(rows);
      expect(result.imported, 1);
      expect(result.skippedCount, 1);
      expect(result.skippedReasons.single, 'Missing required fields');
      expect(result.skipped.single.studentId, '2026-0200');
    });
  });
}