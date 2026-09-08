import 'package:csv/csv.dart';

import '../services/student_service.dart';

/// Default filename used when saving the downloadable CSV template.
const String kStudentCsvTemplateFileName = 'students_import_template.csv';

/// Builds a ready-to-fill CSV template: a header row plus one example row,
/// prefixed with a UTF-8 BOM so Excel opens it with the correct characters.
String buildStudentCsvTemplate() {
  const rows = [
    ['Student ID', 'First Name', 'Last Name', 'Course', 'Year Level'],
    [
      '2026-0100',
      'Juan',
      'Dela Cruz',
      'BS Information Technology',
      '1st Year',
    ],
  ];
  return '\uFEFF${csv.encode(rows)}';
}

/// Parses student rows out of a CSV file's text content.
///
/// The file may (or may not) start with a header row; columns are matched
/// by common label synonyms (e.g. "Student No", "First Name", "Course").
/// When no header is found, the fixed column order is used:
/// student ID, first name, last name, course, year level.
///
/// Year Level may be left blank — it auto-derives from the Student ID
/// (`YYYY-XXXX`). Cells that don't exist are returned as empty strings —
/// rows with missing required fields are skipped later by
/// [StudentService.importStudents].
List<StudentImportRow> parseStudentCsv(String content) {
  final rows = csv.decode(content);
  if (rows.isEmpty) return const [];

  final firstRow = rows.first.map((c) => c.toString()).toList();
  final layout = _detectLayout(firstRow);
  final startIndex = layout == null ? 0 : 1;

  final students = <StudentImportRow>[];
  for (var i = startIndex; i < rows.length; i++) {
    final row = rows[i].map((c) => c.toString()).toList();
    students.add(StudentImportRow(
      studentId: _cell(row, layout, 0),
      firstName: _cell(row, layout, 1),
      lastName: _cell(row, layout, 2),
      course: _cell(row, layout, 3),
      yearLevel: _cell(row, layout, 4),
    ));
  }
  return students;
}

/// Logical field index (0..4) → CSV column index, or null for the fixed
/// column order when the file has no header row.
typedef _Layout = Map<int, int>;

/// Recognized header labels for each logical field, normalized
/// (lowercase, no spaces/underscores/dots).
const Map<int, List<String>> _fieldSynonyms = {
  0: ['studentid', 'studentno', 'studentnumber', 'id', 'idno', 'idnumber', 'lrn'],
  1: ['firstname', 'first', 'givenname', 'given'],
  2: ['lastname', 'last', 'surname', 'familyname', 'family'],
  3: ['course', 'program', 'strand', 'courseprogram', 'programcourse'],
  4: ['yearlevel', 'year', 'level', 'gradelevel', 'grade'],
};

/// Normalizes a header cell: lowercase, keep letters/digits only.
String _normalize(String cell) =>
    cell.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Returns the column layout if [firstRow] looks like a header row,
/// otherwise null (fixed column order).
_Layout? _detectLayout(List<String> firstRow) {
  final normalized = firstRow.map(_normalize).toList();
  final matchedFields = <int>{};

  for (var col = 0; col < normalized.length; col++) {
    final label = normalized[col];
    if (label.isEmpty) continue;
    for (final entry in _fieldSynonyms.entries) {
      if (entry.value.contains(label)) {
        matchedFields.add(entry.key);
        break;
      }
    }
  }

  // Treat the row as a header only if at least two recognizable labels
  // (or at least the student ID label) are present.
  if (matchedFields.isEmpty ||
      (!matchedFields.contains(0) && matchedFields.length < 2)) {
    return null;
  }

  final layout = <int, int>{};
  for (var col = 0; col < normalized.length; col++) {
    final label = normalized[col];
    for (final entry in _fieldSynonyms.entries) {
      if (entry.value.contains(label)) {
        layout[entry.key] = col;
        break;
      }
    }
  }
  return layout;
}

/// Reads a cell for logical field [index], defaulting to '' when the row is
/// too short or the header layout has no column for that field.
String _cell(List<String> row, _Layout? layout, int index) {
  final col = layout?[index] ?? index;
  if (col >= row.length) return '';
  return row[col];
}