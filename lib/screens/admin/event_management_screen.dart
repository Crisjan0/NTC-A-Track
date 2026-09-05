import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
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
    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (_) => const _EventDialog(title: 'New Event'),
    );
    if (draft == null || draft.name.trim().isEmpty) return;

    // If no event is active yet, activate the first one right away so
    // scanning keeps working.
    final hasActive = _events.any((e) => e.isActive);
    await _service.createEvent(
      draft.name,
      setActive: !hasActive,
      flowType: draft.flowType,
    );
    await _load();
  }

  Future<void> _editEvent(AttendanceEvent event) async {
    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (_) => _EventDialog(
        title: 'Edit Event',
        initialName: event.name,
        initialFlowType: event.flowType,
      ),
    );
    if (draft == null || draft.name.trim().isEmpty) return;
    await _service.updateEvent(AttendanceEvent(
      id: event.id,
      name: draft.name,
      isActive: event.isActive,
      flowType: draft.flowType,
      createdAt: event.createdAt,
    ));
    await _load();
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

    return GlassScaffold(
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
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.paletteOf(context).textSecondary,
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
                            onEdit: () => _editEvent(_events[index]),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventRow({
    required this.event,
    required this.recordCount,
    required this.onSetActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: 16,
      blur: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: event.isActive ? AppGradients.primary : null,
              color: event.isActive ? null : p.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: event.isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${recordCount == 0 ? 'No records yet' : '$recordCount ${recordCount == 1 ? 'student' : 'students'}'} · '
                  '${event.usesTimeInOut ? 'AM/PM In & Out' : 'One-time'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit event',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: p.textSecondary,
            ),
          ),
          if (event.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: p.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radio_button_checked_rounded,
                    size: 13,
                    color: p.isDark
                        ? const Color(0xFF34D399)
                        : AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: p.isDark
                          ? const Color(0xFF34D399)
                          : AppColors.success,
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

/// Name + attendance flow chosen in the event dialog.
class _EventDraft {
  final String name;
  final String flowType;

  const _EventDraft({required this.name, required this.flowType});
}

/// A selectable flow-type row inside the event dialog.
class _FlowOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FlowOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? p.primaryContainer
          : p.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : p.isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.9),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : p.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? scheme.primary : p.borderStroke,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog to create or edit an event: name + attendance flow (One-time or
/// AM/PM Time In & Out).
class _EventDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialFlowType;

  const _EventDialog({
    required this.title,
    this.initialName = '',
    this.initialFlowType = EventFlowType.oneTime,
  });

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late final TextEditingController _nameController;
  late String _flowType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _flowType = widget.initialFlowType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      // scrollable keeps the dialog from overflowing on short screens or
      // when the keyboard is open (autofocus on the name field).
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Intrams',
              prefixIcon: Icon(Icons.event_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Attendance Flow',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.paletteOf(context).textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _FlowOption(
            title: 'One-time',
            subtitle: 'One scan per student per day',
            icon: Icons.check_circle_outline_rounded,
            selected: _flowType == EventFlowType.oneTime,
            onTap: () =>
                setState(() => _flowType = EventFlowType.oneTime),
          ),
          const SizedBox(height: 8),
          _FlowOption(
            title: 'Time In/Out',
            subtitle: 'AM & PM sessions — Time In and Time Out each',
            icon: Icons.schedule_rounded,
            selected: _flowType == EventFlowType.timeInOut,
            onTap: () =>
                setState(() => _flowType = EventFlowType.timeInOut),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _EventDraft(
              name: _nameController.text.trim(),
              flowType: _flowType,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(widget.title == 'New Event' ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}