import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/attendance_detail_sheet.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/section_title.dart';
import 'event_management_screen.dart';

/// Admin dashboard: summary stats, active event and recent attendance.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  int _totalStudents = 0;
  int _presentToday = 0;
  int _incompleteToday = 0;
  int _absentToday = 0;
  int _totalAttendance = 0;
  List<Attendance> _recent = [];
  List<Student> _absentStudents = [];
  List<Student> _incompleteStudents = [];
  String? _activeEventName;
  bool _recentExpanded = false;
  bool _absentExpanded = false;
  bool _incompleteExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AttendanceService.instance.dashboardStats();
    final recent =
        await AttendanceService.instance.recentAttendance(limit: 6);
    final absent = await AttendanceService.instance.absentStudentsToday();
    final incomplete =
        await AttendanceService.instance.incompleteStudentsToday();
    if (!mounted) return;
    setState(() {
      _totalStudents = stats.totalStudents;
      _presentToday = stats.presentToday;
      _incompleteToday = stats.incompleteToday;
      _absentToday = stats.absentToday;
      _totalAttendance = stats.totalAttendance;
      _recent = recent;
      _absentStudents = absent;
      _incompleteStudents = incomplete;
      _activeEventName = stats.eventName;
      _loading = false;
    });
  }

  Future<void> _openEvents() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EventManagementScreen()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance.current;
    final isAdmin = session?.isAdmin ?? false;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: isAdmin ? 'Admin Dashboard' : 'Dashboard',
                subtitle: Formatters.fullDate(DateTime.now()),
                icon: Icons.space_dashboard_rounded,
                trailing: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    // Summary cards.
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            label: 'Total Students',
                            value: '$_totalStudents',
                            icon: Icons.group_rounded,
                            gradient: AppGradients.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardCard(
                            label: 'Present Today',
                            value: '$_presentToday',
                            icon: Icons.check_circle_rounded,
                            gradient: AppGradients.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            label: 'Absent Today',
                            value: '$_absentToday',
                            icon: Icons.cancel_rounded,
                            gradient: AppGradients.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardCard(
                            label: 'Incomplete Today',
                            value: '$_incompleteToday',
                            hint: 'Missing AM/PM scans',
                            icon: Icons.hourglass_bottom_rounded,
                            gradient: AppGradients.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            label: 'Total Attendance',
                            value: '$_totalAttendance',
                            icon: Icons.event_available_rounded,
                            gradient: AppGradients.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Active Event'),
                    const SizedBox(height: 12),
                    _ActiveEventBanner(
                      eventName: _activeEventName,
                      onManage: _openEvents,
                    ),
                    const SizedBox(height: 24),
                    // Collapsible "Absent Today" dropdown: students with no
                    // record today for the active event.
                    GlassPanel(
                      radius: 16,
                      blur: 18,
                      padding: EdgeInsets.zero,
                      onTap: () =>
                          setState(() => _absentExpanded = !_absentExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_off_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Absent Today',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.paletteOf(context).textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '$_absentToday',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color:
                                    AppTheme.paletteOf(context).textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _absentExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppTheme.paletteOf(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_absentExpanded) ...[
                      const SizedBox(height: 12),
                      if (_absentStudents.isEmpty)
                        const EmptyState(
                          icon: Icons.check_circle_rounded,
                          title: 'No absents',
                          subtitle:
                              'Everyone has at least one record today for the active event',
                        )
                      else
                        ..._absentStudents.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StatusStudentRow(
                              student: s,
                              badgeText: 'ABSENT',
                              badgeColor: AppColors.danger,
                              avatarGradient: AppGradients.danger,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    // Collapsible "Incomplete Today" dropdown: students with
                    // a partial Time In/Out day (missing AM/PM scans).
                    GlassPanel(
                      radius: 16,
                      blur: 18,
                      padding: EdgeInsets.zero,
                      onTap: () => setState(
                          () => _incompleteExpanded = !_incompleteExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.warning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.hourglass_bottom_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Incomplete Today',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.paletteOf(context).textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '$_incompleteToday',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color:
                                    AppTheme.paletteOf(context).textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _incompleteExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppTheme.paletteOf(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_incompleteExpanded) ...[
                      const SizedBox(height: 12),
                      if (_incompleteStudents.isEmpty)
                        const EmptyState(
                          icon: Icons.check_circle_rounded,
                          title: 'No incomplete records',
                          subtitle:
                              'Everyone either completed all scans or has no record yet',
                        )
                      else
                        ..._incompleteStudents.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StatusStudentRow(
                              student: s,
                              badgeText: 'INCOMPLETE',
                              badgeColor: AppColors.warning,
                              avatarGradient: AppGradients.warning,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    // Collapsible "Recent Attendance" dropdown.
                    GlassPanel(
                      radius: 16,
                      blur: 18,
                      padding: EdgeInsets.zero,
                      onTap: () =>
                          setState(() => _recentExpanded = !_recentExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event_note_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Recent Attendance',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.paletteOf(context).textPrimary,
                                ),
                              ),
                            ),
                            if (_recent.isNotEmpty) ...[
                              Text(
                                '${_recent.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      AppTheme.paletteOf(context).textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            AnimatedRotation(
                              turns: _recentExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppTheme.paletteOf(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_recentExpanded) ...[
                      const SizedBox(height: 12),
                      if (_recent.isEmpty)
                        const EmptyState(
                          icon: Icons.event_note_rounded,
                          title: 'No attendance yet',
                          subtitle: 'Scan a student QR code to record attendance',
                        )
                      else
                        ..._recent.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AttendanceCard(
                              record: r,
                              onTap: () =>
                                  AttendanceDetailSheet.show(context, r),
                            ),
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// One row in the "Absent Today" / "Incomplete Today" lists.
class _StatusStudentRow extends StatelessWidget {
  final Student student;
  final String badgeText;
  final Color badgeColor;
  final LinearGradient avatarGradient;

  const _StatusStudentRow({
    required this.student,
    required this.badgeText,
    required this.badgeColor,
    required this.avatarGradient,
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
              gradient: avatarGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                student.initials,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.studentId} · ${student.course}',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner showing which event attendance is currently being recorded to.
class _ActiveEventBanner extends StatelessWidget {
  final String? eventName;
  final VoidCallback onManage;

  const _ActiveEventBanner({required this.eventName, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 18,
      blur: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppGradients.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECORDING ATTENDANCE TO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eventName ?? 'General Attendance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              'Manage',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: scheme.primary,
              ),
            ),
          ),        ],
      ),
    );
  }
}
