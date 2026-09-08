/// Represents a student record.
///
/// For the local demo, each student also carries their own credentials
/// (password hash + salt) so they can log in independently.
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