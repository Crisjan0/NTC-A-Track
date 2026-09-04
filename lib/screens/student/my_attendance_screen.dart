import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/event_model.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';

/// Student's own attendance history (read-only).
///
/// Shows an overview of the events the student has attended (with counts),
/// which can be tapped to filter the records below to a single event.
class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  bool _loading = true;
  List<Attendance> _history = [];
  List<StudentEventSummary> _events = [];
  Student? _student;

  /// null = showing all records; otherwise the selected event id.
  int? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final student = await AuthService.instance.currentStudent();
    if (student == null) return;

    final history =
        await AttendanceService.instance.studentHistory(student.studentId);
    final events =
        await AttendanceService.instance.studentEvents(student.studentId);
    if (!mounted) return;
    setState(() {
      _student = student;
      _history = history;
      _events = events;
      _loading = false;
      // Drop the filter if the selected event no longer exists.
      if (_selectedEventId != null &&
          !events.any((e) => e.event.id == _selectedEventId)) {
        _selectedEventId = null;
      }
    });
  }

  List<Attendance> get _visibleRecords {
    final records = _history.where((r) => r.status != AttendanceStatus.absent);
    if (_selectedEventId == null) return records.toList();
    return records.where((r) => r.eventId == _selectedEventId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'My Attendance',
            subtitle: _student?.fullName,
            icon: Icons.event_note_rounded,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'No attendance yet',
                        subtitle:
                            'Ask the admin to scan your QR code to get started',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            if (_events.isNotEmpty) ...[
                              _EventsChips(
                                events: _events,
                                selectedEventId: _selectedEventId,
                                onSelect: (id) => setState(
                                  () => _selectedEventId = id,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            for (final record in _visibleRecords)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AttendanceCard(
                                  record: record,
                                  showStudent: false,
                                ),
                              ),
                            if (_visibleRecords.isEmpty)
                              const EmptyState(
                                icon: Icons.event_busy_rounded,
                                title: 'No records here',
                                subtitle:
                                    'No attendance found for the selected event',
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable chips: one per event the student attended, with a
/// count badge. Tapping a chip filters the history to that event.
class _EventsChips extends StatelessWidget {
  final List<StudentEventSummary> events;
  final int? selectedEventId;
  final ValueChanged<int> onSelect;

  const _EventsChips({
    required this.events,
    required this.selectedEventId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final summary = events[index];
          final event = summary.event;
          final isActive = _eventIsActive(event);
          final selected = event.id == selectedEventId;
          return Material(
            color: selected ? AppColors.primary : AppColors.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? AppColors.primary
                    : isActive
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.border,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelect(event.id!),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 15,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.indigoLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${summary.timesAttended}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _eventIsActive(AttendanceEvent event) => event.isActive;
}