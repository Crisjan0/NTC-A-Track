import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/section_title.dart';
import 'admin_shell.dart';
import 'event_management_screen.dart';
import 'qr_scanner_screen.dart';
import 'student_management_screen.dart';

/// Admin dashboard: summary stats, quick actions and recent attendance.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  int _totalStudents = 0;
  int _presentToday = 0;
  int _absentToday = 0;
  int _totalAttendance = 0;
  List<Attendance> _recent = [];
  String? _activeEventName;

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
    if (!mounted) return;
    setState(() {
      _totalStudents = stats.totalStudents;
      _presentToday = stats.presentToday;
      _absentToday = stats.absentToday;
      _totalAttendance = stats.totalAttendance;
      _recent = recent;
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
                            label: 'Total Attendance',
                            value: '$_totalAttendance',
                            icon: Icons.event_available_rounded,
                            gradient: AppGradients.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan QR',
                            gradient: AppGradients.primary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const QrScannerScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.person_add_alt_1_rounded,
                            label: 'Add Student',
                            gradient: AppGradients.success,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentManagementScreen(addMode: true),
                                ),
                              );
                              _load();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.group_rounded,
                            label: 'Students',
                            gradient: AppGradients.warning,
                            onTap: () => _switchTab(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.event_note_rounded,
                            label: 'Attendance',
                            gradient: AppGradients.info,
                            onTap: () => _switchTab(3),
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
                    const SectionTitle(
                      title: 'Recent Attendance',
                      actionLabel: 'View all',
                      onAction: null,
                    ),
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
                          child: AttendanceCard(record: r),
                        ),
                      ),
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

  void _switchTab(int index) {
    // Ask the shell (an ancestor in the tree) to change tabs.
    context.findAncestorStateOfType<AdminShellState>()?.switchTo(index);
  }
}

/// Banner showing which event attendance is currently being recorded to.
class _ActiveEventBanner extends StatelessWidget {
  final String? eventName;
  final VoidCallback onManage;

  const _ActiveEventBanner({required this.eventName, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
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
                const Text(
                  'RECORDING ATTENDANCE TO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  eventName ?? 'General Attendance',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Manage',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: 16,
      blur: 18,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}