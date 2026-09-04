/// Represents a single attendance record.
///
/// The database enforces one record per student per day per event
/// (UNIQUE constraint on student_id + date + event_id) to prevent
/// duplicates while allowing a student to attend several events in a day.
class Attendance {
  final int? id;
  final String studentId;
  final DateTime date;
  final DateTime time;
  final String status;
  final int? eventId;
  final DateTime createdAt;

  // Joined student fields (populated by queries that JOIN students).
  final String? studentName;
  final String? course;
  final String? yearLevel;

  // Joined event field (populated by queries that JOIN events).
  final String? eventName;

  const Attendance({
    this.id,
    required this.studentId,
    required this.date,
    required this.time,
    required this.status,
    this.eventId,
    required this.createdAt,
    this.studentName,
    this.course,
    this.yearLevel,
    this.eventName,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    final date = DateTime.parse(map['date'] as String);
    final timeStr = map['time'] as String;
    final timeParts = timeStr.split(':').map(int.parse).toList();
    return Attendance(
      id: map['id'] as int?,
      studentId: map['student_id'] as String,
      date: date,
      time: DateTime(date.year, date.month, date.day, timeParts[0], timeParts[1]),
      status: map['status'] as String? ?? 'PRESENT',
      eventId: map['event_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      studentName: map['full_name'] as String?,
      course: map['course'] as String?,
      yearLevel: map['year_level'] as String?,
      eventName: map['event_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'date': date.toIso8601String().substring(0, 10),
        'time':
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'status': status,
        if (eventId != null) 'event_id': eventId,
        'created_at': createdAt.toIso8601String(),
      };
}