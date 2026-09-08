import '../utils/year_level.dart';

/// Represents a student record.
///
/// For the local demo, each student also carries their own credentials
/// (password hash + salt) so they can log in independently.
///
/// Year level is AUTO-DERIVED from [studentId] (`YYYY-XXXX` -> entry year)
/// via [displayYearLevel]. The stored [yearLevel] is only a fallback for
/// old/non-standard IDs (e.g. `12345`) — no database change needed.
class Student {
  final String? id;
  final String studentId;
  final String lastName;
  final String firstName;
  final String course;
  final String yearLevel;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const Student({
    this.id,
    required this.studentId,
    required this.lastName,
    required this.firstName,
    required this.course,
    required this.yearLevel,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  /// Auto year level from the Student ID (e.g. `2024-5648` -> `3rd Year`
  /// in S.Y. 2026-2027). Falls back to the stored [yearLevel] when the ID
  /// has no `YYYY-` prefix. Use this everywhere in the UI.
  String get displayYearLevel => YearLevelAuto.effective(
        studentId: studentId,
        storedYearLevel: yearLevel,
      );

  /// True when the year level is auto-computed (not manually stored).
  bool get isYearLevelAuto => YearLevelAuto.isAuto(studentId);

  /// "Juan Dela Cruz" -> "JD"
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    return letters.toUpperCase();
  }

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id: map['id']?.toString(),
        studentId: map['student_id'] as String,
        lastName: map['last_name'] as String,
        firstName: map['first_name'] as String,
        course: map['course'] as String,
        yearLevel: map['year_level'] as String,
        passwordHash: map['password_hash'] as String,
        salt: map['salt'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'last_name': lastName,
        'first_name': firstName,
        'course': course,
        'year_level': yearLevel,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': createdAt.toIso8601String(),
      };
}