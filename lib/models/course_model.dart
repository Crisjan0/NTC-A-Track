/// Represents an academic course managed by the admin.
class Course {
  final String? id;
  final String name;
  final DateTime createdAt;

  const Course({
    this.id,
    required this.name,
    required this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) => Course(
        id: map['id'] as String?,
        name: map['course_name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'course_name': name,
        'created_at': createdAt.toIso8601String(),
      };
}
