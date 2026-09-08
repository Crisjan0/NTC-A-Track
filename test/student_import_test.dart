import 'package:attendancesystem/utils/student_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
