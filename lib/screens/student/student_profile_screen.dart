import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/constants.dart';
import '../../widgets/avatar.dart';
import '../../widgets/gradient_header.dart';
import '../auth/role_selection_screen.dart';

/// Student profile: personal details + logout.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Student?>(
      future: AuthService.instance.currentStudent(),
      builder: (context, snapshot) {
        final student = snapshot.data;
        final session = SessionService.instance.current;

        return Scaffold(
          body: Column(
            children: [
              const GradientHeader(
                title: 'Profile',
                subtitle: 'Your account information',
                icon: Icons.person_rounded,
              ),
              Expanded(
                child: student == null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(kCardRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  InitialsAvatar(
                                    initials: student.initials,
                                    radius: 28,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    student.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    student.studentId,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  _ProfileRow(
                                    icon: Icons.menu_book_rounded,
                                    label: 'Course',
                                    value: student.course,
                                  ),
                                  _ProfileRow(
                                    icon: Icons.grade_rounded,
                                    label: 'Year Level',
                                    value: student.yearLevel,
                                  ),
                                  _ProfileRow(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Username',
                                    value: session?.username ?? student.studentId,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () => _logout(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                    color: AppColors.dangerLight,
                                  ),
                                  backgroundColor: AppColors.dangerLight,
                                ),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}