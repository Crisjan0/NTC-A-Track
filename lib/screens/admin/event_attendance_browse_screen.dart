import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/event_model.dart';
import '../../services/attendance_service.dart';
import '../../utils/constants.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';

/// Drill-down browse of attendance records, organized as:
///   Event → Course → Student records.
///
/// Start by picking an event, then a course with attendance for that
/// event, and the individual student records are listed last.
class EventAttendanceBrowseScreen extends StatefulWidget {
  const EventAttendanceBrowseScreen({super.key});

  @override
  State<EventAttendanceBrowseScreen> createState() =>
      _EventAttendanceBrowseScreenState();
}

class _EventAttendanceBrowseScreenState
    extends State<EventAttendanceBrowseScreen> {
  final AttendanceService _service = AttendanceService.instance;

  // null = still loading that level.
  List<AttendanceEvent>? _events;
  Map<int, int>? _countsByEvent;
  AttendanceEvent? _event;
  Map<String, int>? _courseCounts;
  String? _course;
  List<Attendance>? _records;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _events = null);
    final events = await _service.allEvents();
    final counts = await _service.attendanceCountByEvent();
    if (!mounted) return;
    setState(() {
      _events = events;
      _countsByEvent = counts;
    });
  }

  Future<void> _selectEvent(AttendanceEvent event) async {
    setState(() {
      _event = event;
      _course = null;
      _courseCounts = null;
      _records = null;
    });
    final counts = await _service.courseCountsForEvent(event.id!);
    if (!mounted) return;
    setState(() => _courseCounts = counts);
  }

  Future<void> _selectCourse(String course) async {
    setState(() {
      _course = course;
      _records = null;
    });
    final records = await _service.queryAttendance(
      eventId: _event!.id,
      course: course,
    );
    if (!mounted) return;
    setState(() => _records = records);
  }

  bool get _canPop => _event == null && _course == null;

  void _goBack() {
    if (_course != null) {
      setState(() {
        _course = null;
        _records = null;
      });
    } else if (_event != null) {
      setState(() {
        _event = null;
        _courseCounts = null;
        _records = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;

    if (_course != null) {
      title = _course!;
      subtitle = '${_event!.name} · students who attended';
    } else if (_event != null) {
      title = _event!.name;
      subtitle = 'Courses with attendance for this event';
    } else {
      title = 'Browse by Event';
      subtitle = 'Pick an event to see who attended';
    }

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: title,
              subtitle: subtitle,
              icon: Icons.emoji_events_rounded,
              leading: IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              trailing: _course != null
                  ? null
                  : IconButton(
                      onPressed: _loadEvents,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_course != null) return _buildRecords();
    if (_event != null) return _buildCourses();
    return _buildEvents();
  }

  Widget _buildEvents() {
    final events = _events;
    if (events == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (events.isEmpty) {
      return const EmptyState(
        icon: Icons.event_rounded,
        title: 'No events yet',
        subtitle: 'Create an event to start browsing attendance',
      );
    }
    final counts = _countsByEvent ?? const {};
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final event = events[index];
          final count = counts[event.id] ?? 0;
          return _BrowseTile(
            icon: event.isActive
                ? Icons.emoji_events_rounded
                : Icons.event_rounded,
            title: event.name,
            subtitle: count == 0
                ? 'No attendance records'
                : '$count ${count == 1 ? 'record' : 'records'}',
            trailing: event.isActive ? const _ActiveBadge() : null,
            onTap: () => _selectEvent(event),
          );
        },
      ),
    );
  }

  Widget _buildCourses() {
    final counts = _courseCounts;
    if (counts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (counts.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No attendance for ${_event!.name}',
        subtitle: 'Records appear here after QR scans for this event',
      );
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _BrowseTile(
          icon: Icons.menu_book_rounded,
          title: entry.key,
          subtitle: '${entry.value} ${entry.value == 1 ? 'student' : 'students'} attended',
          onTap: () => _selectCourse(entry.key),
        );
      },
    );
  }

  Widget _buildRecords() {
    final records = _records;
    if (records == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No records yet',
        subtitle: 'No attendance for ${_event!.name} under $_course',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _selectCourse(_course!);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            AttendanceCard(record: records[index]),
      ),
    );
  }
}

/// Reusable tappable row for the event / course levels.
class _BrowseTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _BrowseTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.indigoLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: AppColors.success,
        ),
      ),
    );
  }
}