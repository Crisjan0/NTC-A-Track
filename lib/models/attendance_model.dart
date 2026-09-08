import '../utils/constants.dart';

/// Represents a single attendance record.
///
/// The database enforces one record per student per day per event per
/// [checkType] (UNIQUE constraint on student_id + date + event_id +
/// check_type) to prevent duplicates while allowing a student to attend
/// several events in a day and to scan Time In / Time Out for events with
/// the AM/PM flow.
class Attendance {
  final String? id;
  final String studentId;
  final DateTime date;
  final DateTime time;
  final String status;

  /// What this record is: [CheckType.present] for one-time events, or one
  /// of the AM/PM Time In / Time Out combinations for in/out events.
  final String checkType;
  final String? eventId;
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
    this.checkType = CheckType.present,
    this.eventId,
    required this.createdAt,
    this.studentName,
    this.course,
    this.yearLevel,
    this.eventName,
  });

  Attendance copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    DateTime? time,
    String? status,
    String? checkType,
    String? eventId,
    DateTime? createdAt,
    String? studentName,
    String? course,
    String? yearLevel,
    String? eventName,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      checkType: checkType ?? this.checkType,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      studentName: studentName ?? this.studentName,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      eventName: eventName ?? this.eventName,
    );
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    final date = DateTime.parse(map['date'] as String);
    final timeStr = map['time'] as String;
    final timeParts = timeStr.split(':').map(int.parse).toList();
    return Attendance(
      id: map['id']?.toString(),
      studentId: map['student_id'].toString(),
      date: date,
      time: DateTime(date.year, date.month, date.day, timeParts[0], timeParts[1]),
      status: map['status'] as String? ?? 'PRESENT',
      checkType: map['check_type'] as String? ?? CheckType.present,
      eventId: map['event_id']?.toString(),
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
        'check_type': checkType,
        if (eventId != null) 'event_id': eventId,
        'created_at': createdAt.toIso8601String(),
      };
}