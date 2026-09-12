import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/event_model.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/attendance_detail_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import 'event_attendance_browse_screen.dart';

/// Admin attendance records: searchable + filterable by date, course,
/// year level and status.
class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  final AttendanceService _service = AttendanceService.instance;
  final _searchController = TextEditingController();

  List<Attendance> _records = [];
  List<AttendanceEvent> _events = [];
  bool _loading = true;

  String? _date;
  String? _course;
  String? _yearLevel;
  String? _status;
  String? _eventId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_events.isEmpty) {
      _events = await _service.allEvents();
    }
    final records = await _service.queryAttendance(
      search: _searchController.text,
      date: _date,
      course: _course,
      yearLevel: _yearLevel,
      status: _status,
      eventId: _eventId,
    );
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Filter by date',
    );
    if (picked == null) return;
    setState(() {
      _date = Formatters.dbDate(picked);
    });
    _load();
  }

  Future<void> _openBrowse() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EventAttendanceBrowseScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Attendance Records',
            subtitle: '${_records.length} ${_records.length == 1 ? 'record' : 'records'}',
            icon: Icons.event_note_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    final p = AppTheme.paletteOf(context);
                    final scheme = Theme.of(context).colorScheme;
                    return GlassPanel(
                      radius: 14,
                      blur: 16,
                      borderWidth: 0.8,
                      showSheen: false,
                      color: scheme.primary,
                      onTap: _openBrowse,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_tree_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Browse by Event',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Event → Course → Student records',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Search by ID or name…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: _date == null
                            ? 'All Dates'
                            : Formatters.shortDate(DateTime.parse(_date!)),
                        icon: Icons.calendar_month_rounded,
                        active: _date != null,
                        onTap: _pickDate,
                        onClear: _date == null
                            ? null
                            : () {
                                setState(() => _date = null);
                                _load();
                              },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: _course ?? 'All Courses',
                        icon: Icons.menu_book_rounded,
                        active: _course != null,
                        onTap: () => _showCourseSheet(),
                        onClear: _course == null
                            ? null
                            : () {
                                setState(() => _course = null);
                                _load();
                              },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: _yearLevel ?? 'All Years',
                        icon: Icons.grade_rounded,
                        active: _yearLevel != null,
                        onTap: () => _showYearSheet(),
                        onClear: _yearLevel == null
                            ? null
                            : () {
                                setState(() => _yearLevel = null);
                                _load();
                              },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: _eventLabel,
                        icon: Icons.emoji_events_rounded,
                        active: _eventId != null,
                        onTap: () => _showEventSheet(),
                        onClear: _eventId == null
                            ? null
                            : () {
                                setState(() => _eventId = null);
                                _load();
                              },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: _status ?? 'All Status',
                        icon: Icons.flag_rounded,
                        active: _status != null,
                        onTap: () => _showStatusSheet(),
                        onClear: _status == null
                            ? null
                            : () {
                                setState(() => _status = null);
                                _load();
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'No attendance records',
                        subtitle:
                            'Records appear here after QR scans are completed',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _records.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            return AttendanceCard(
                              record: record,
                              onTap: () =>
                                  AttendanceDetailSheet.show(context, record),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCourseSheet() async {
    final picked = await _showPickerSheet<String>(
      title: 'Filter by Course',
      items: kCourses,
    );
    if (picked == null) return;
    setState(() => _course = picked == '' ? null : picked);
    _load();
  }

  Future<void> _showYearSheet() async {
    final picked = await _showPickerSheet<String>(
      title: 'Filter by Year Level',
      items: kYearLevels,
    );
    if (picked == null) return;
    setState(() => _yearLevel = picked == '' ? null : picked);
    _load();
  }

  Future<void> _showEventSheet() async {
    final picked = await _showPickerSheet<String>(
      title: 'Filter by Event',
      items: _events.map((e) => e.name).toList(),
    );
    if (picked == null) return;
    setState(() {
      final match = _events.where((e) => e.name == picked).toList();
      _eventId = picked == '' ? null : (match.isEmpty ? null : match.first.id);
    });
    _load();
  }

  Future<void> _showStatusSheet() async {
    final picked = await _showPickerSheet<String>(
      title: 'Filter by Status',
      items: const [
        AttendanceStatus.present,
        AttendanceStatus.incomplete,
        AttendanceStatus.absent,
      ],
    );
    if (picked == null) return;
    setState(() => _status = picked == '' ? null : picked);
    _load();
  }

  String get _eventLabel {
    if (_eventId == null) return 'All Events';
    final match = _events.where((e) => e.id == _eventId).toList();
    return match.isEmpty ? 'All Events' : match.first.name;
  }

  Future<String?> _showPickerSheet<T>({
    required String title,
    required List<T> items,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.paletteOf(ctx).textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all_rounded),
              title: const Text('All'),
              onTap: () => Navigator.of(ctx).pop(''),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: items
                    .map(
                      (item) => ListTile(
                        title: Text('$item'),
                        onTap: () => Navigator.of(ctx).pop('$item'),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = active ? scheme.primary : p.textSecondary;
    final bg = active
        ? p.primaryContainer
        : p.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.55);
    final border = active
        ? scheme.primary.withValues(alpha: 0.5)
        : p.isDark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.9);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded, size: 15, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}