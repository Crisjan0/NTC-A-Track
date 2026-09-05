import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/section_title.dart';
import 'student_shell.dart';

/// Student dashboard: welcome, personal info and attendance summary.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _loading = true;
  Student? _student;
  int _total = 0;
  int _present = 0;
  int _absent = 0;
  double _rate = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final student = await AuthService.instance.currentStudent();
    if (student == null) return;

    final summary = await AttendanceService.instance.studentSummary(
      student.studentId,
    );
    if (!mounted) return;
    setState(() {
      _student = student;
      _total = summary.total;
      _present = summary.present;
      _absent = summary.absent;
      _rate = summary.rate;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    final student = _student;
    final session = SessionService.instance.current;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: student == null
                    ? 'Student Dashboard'
                    : 'Welcome, ${student.firstName}',
                subtitle: session?.fullName ?? '',
                icon: Icons.emoji_events_rounded,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverList.list(
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (student == null)
                    const SizedBox()
                  else ...[
                    // Personal info — one clean frosted surface.
                    GlassPanel(
                      radius: kCardRadius,
                      blur: 24,
                      strong: true,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      student.studentId,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoLine(
                            label: 'Course',
                            value: student.course,
                          ),
                          const SizedBox(height: 8),
                          _InfoLine(
                            label: 'Year Level',
                            value: student.yearLevel,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Attendance Summary'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            label: 'Days Attended',
                            value: '$_present',
                            icon: Icons.check_circle_rounded,
                            gradient: AppGradients.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardCard(
                            label: 'Days Missed',
                            value: '$_absent',
                            icon: Icons.cancel_rounded,
                            gradient: AppGradients.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            label: 'Total Days',
                            value: '$_total',
                            icon: Icons.calendar_month_rounded,
                            gradient: AppGradients.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DashboardCard(
                            label: 'Attendance Rate',
                            value: Formatters.percent(_rate),
                            icon: Icons.percent_rounded,
                            gradient: AppGradients.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Quick Access'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.qr_code_2_rounded,
                            label: 'My QR Code',
                            gradient: AppGradients.primary,
                            onTap: () => _switchTab(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.event_note_rounded,
                            label: 'My Attendance',
                            gradient: AppGradients.orange,
                            onTap: () => _switchTab(2),
                          ),
                        ),
                      ],
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
    context.findAncestorStateOfType<StudentShellState>()?.switchTo(index);
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return Row(
      children: [
        Text(
          '$label:  ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: p.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 14),
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
