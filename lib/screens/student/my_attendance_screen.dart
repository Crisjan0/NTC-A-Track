import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/event_model.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
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
  String? _selectedEventId;

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
    // With no event selected show everything (absent days included). When an
    // event chip is selected, only that event's records remain (absent days
    // belong to no event, so they drop out naturally).
    final records =
        _history.where((r) => _selectedEventId == null || r.eventId == _selectedEventId);
    return records.toList();
  }

  /// Groups the visible records so Time In/Out checks for the same day +
  /// event render as one card instead of four separate rows.
  List<Widget> _buildHistoryRows() {
    final groups = <String, List<Attendance>>{};
    for (final r in _visibleRecords) {
      final key = '${Formatters.dbDate(r.date)}#${r.eventId}';
      groups.putIfAbsent(key, () => []).add(r);
    }

    final rows = <Widget>[];
    for (final group in groups.values) {
      final isAbsentDay =
          group.every((r) => r.status == AttendanceStatus.absent);
      final isInOutDay = group.any((r) => r.checkType != CheckType.present);

      final Widget card = (isAbsentDay || (!isInOutDay && group.length == 1))
          ? AttendanceCard(record: group.first, showStudent: false)
          : _DayAttendanceCard(records: group);
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: card,
      ));
    }
    return rows;
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
                            ..._buildHistoryRows(),
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
  final String? selectedEventId;
  final ValueChanged<String> onSelect;

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
          final p = AppTheme.paletteOf(context);
          return Material(
            color: selected
                ? AppColors.primary
                : p.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.55),
            shape: StadiumBorder(
              side: BorderSide(
                color: selected
                    ? AppColors.primary
                    : isActive
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : p.isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.9),
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
                        color: selected ? Colors.white : p.textPrimary,
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
                            : p.primaryContainer,
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

/// One day card for a Time In/Out event: shows the AM/PM Time In and Time
/// Out of the student for that day + event. Missing checks show "—".
class _DayAttendanceCard extends StatelessWidget {
  final List<Attendance> records;

  const _DayAttendanceCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final first = records.first;
    final eventName = records
            .map((r) => r.eventName)
            .firstWhere((n) => n != null, orElse: () => null) ??
        'Attendance';
    final byCheck = {for (final r in records) r.checkType: r};

    Attendance? recordFor(String check) => byCheck[check];

    return GlassPanel(
      radius: 18,
      blur: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${first.date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.isDark ? p.onPrimaryContainer : AppColors.primary,
                  ),
                ),
                Text(
                  _monthAbbr(first.date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.isDark ? p.onPrimaryContainer : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _CheckRow(
                  label: 'AM Time In',
                  icon: Icons.login_rounded,
                  color: AppColors.info,
                  record: recordFor(CheckType.amIn),
                ),
                _CheckRow(
                  label: 'AM Time Out',
                  icon: Icons.logout_rounded,
                  color: AppColors.warning,
                  record: recordFor(CheckType.amOut),
                ),
                _CheckRow(
                  label: 'PM Time In',
                  icon: Icons.login_rounded,
                  color: AppColors.info,
                  record: recordFor(CheckType.pmIn),
                ),
                _CheckRow(
                  label: 'PM Time Out',
                  icon: Icons.logout_rounded,
                  color: AppColors.warning,
                  record: recordFor(CheckType.pmOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[d.month - 1];
  }
}

/// One Time In / Time Out line inside a [_DayAttendanceCard].
class _CheckRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Attendance? record;

  const _CheckRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final rec = record;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: rec == null ? p.borderStroke : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            rec == null ? '—' : Formatters.time(rec.time),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: rec == null ? p.textSecondary : p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}