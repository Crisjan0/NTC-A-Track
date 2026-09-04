import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../services/attendance_service.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';

/// Admin event management: create events, set which one is active, and
/// delete events that are no longer needed. QR scans are always recorded
/// to the active event.
class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final AttendanceService _service = AttendanceService.instance;

  List<AttendanceEvent> _events = [];
  Map<int, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final events = await _service.allEvents();
    final counts = await _service.attendanceCountByEvent();
    if (!mounted) return;
    setState(() {
      _events = events;
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _addEvent() async {
    final name = await _promptForName();
    if (name == null || name.trim().isEmpty) return;

    // If no event is active yet, activate the first one right away so
    // scanning keeps working.
    final hasActive = _events.any((e) => e.isActive);
    await _service.createEvent(name, setActive: !hasActive);
    await _load();
  }

  Future<String?> _promptForName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Event'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Intrams',
            prefixIcon: Icon(Icons.event_rounded),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _setActive(AttendanceEvent event) async {
    await _service.setActiveEvent(event.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Now recording to: ${event.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _load();
  }

  Future<void> _confirmDelete(AttendanceEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${event.name}"?'),
        content: const Text(
          'Attendance records for this event are kept, but will no longer '
          'be tagged to it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _service.deleteEvent(event.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${event.name}" deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _events.where((e) => e.isActive).toList();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Manage Events',
            subtitle: active.isEmpty
                ? 'No active event yet'
                : 'Scans are recorded to: ${active.first.name}',
            icon: Icons.emoji_events_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addEvent,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Event'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Tap "Set Active" on an event to switch attendance to it. '
              'The active event cannot be deleted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_rounded,
                        title: 'No events yet',
                        subtitle:
                            'Create your first event to start recording '
                            'attendance for it',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _events.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _EventRow(
                            event: _events[index],
                            recordCount: _counts[_events[index].id] ?? 0,
                            onSetActive: () => _setActive(_events[index]),
                            onDelete: () => _confirmDelete(_events[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final AttendanceEvent event;
  final int recordCount;
  final VoidCallback onSetActive;
  final VoidCallback onDelete;

  const _EventRow({
    required this.event,
    required this.recordCount,
    required this.onSetActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: event.isActive ? AppGradients.primary : null,
              color: event.isActive ? null : AppColors.indigoLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.isActive
                  ? Icons.emoji_events_rounded
                  : Icons.event_rounded,
              color: event.isActive ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recordCount == 0
                      ? 'No records yet'
                      : '$recordCount ${recordCount == 1 ? 'record' : 'records'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (event.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radio_button_checked_rounded,
                    size: 13,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextButton(
              onPressed: onSetActive,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'Set Active',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete event',
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}