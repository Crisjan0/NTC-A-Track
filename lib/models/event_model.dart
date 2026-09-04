/// Represents an attendance event (e.g. "Intrams", "Foundation Day").
///
/// Exactly one event is *active* at a time; QR scans are recorded to the
/// active event. Attendance rows reference the event they were scanned for.
class AttendanceEvent {
  final int? id;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  const AttendanceEvent({
    this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  factory AttendanceEvent.fromMap(Map<String, dynamic> map) => AttendanceEvent(
        id: map['id'] as int?,
        name: map['name'] as String,
        isActive: (map['is_active'] as int?) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}