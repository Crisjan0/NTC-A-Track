import '../utils/constants.dart';

/// Represents an attendance event (e.g. "Intrams", "Foundation Day").
///
/// Exactly one event is *active* at a time; QR scans are recorded to the
/// active event. Attendance rows reference the event they were scanned for.
///
/// Each event also has an attendance [flowType]:
///  - [EventFlowType.oneTime]: one scan per student per day (default)
///  - [EventFlowType.timeInOut]: AM + PM sessions, each with a Time In and
///    a Time Out scan
class AttendanceEvent {
  final String? id;
  final String name;
  final bool isActive;
  final String flowType;
  final DateTime createdAt;

  const AttendanceEvent({
    this.id,
    required this.name,
    required this.isActive,
    this.flowType = EventFlowType.oneTime,
    required this.createdAt,
  });

  /// Whether this event uses AM/PM Time In + Time Out scanning.
  bool get usesTimeInOut => flowType == EventFlowType.timeInOut;

  factory AttendanceEvent.fromMap(Map<String, dynamic> map) => AttendanceEvent(
        id: map['id']?.toString(),
        name: map['name'] as String,
        isActive: map['is_active'] as bool? ?? false,
        flowType: map['flow_type'] as String? ?? EventFlowType.oneTime,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'is_active': isActive,
        'flow_type': flowType,
        'created_at': createdAt.toIso8601String(),
      };
}