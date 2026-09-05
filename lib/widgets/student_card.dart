import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'avatar.dart';
import 'glass_panel.dart';

/// A frosted glass student row card shown in admin student management.
class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewQr;

  const StudentCard({
    super.key,
    required this.student,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.onViewQr,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;

    return GlassPanel(
      radius: kCardRadius,
      blur: 24,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialsAvatar(initials: student.initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.studentId,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _InfoTag(
                                icon: Icons.menu_book_rounded,
                                label: student.course,
                              ),
                              _InfoTag(
                                icon: Icons.grade_rounded,
                                label: student.yearLevel,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onViewQr,
                      tooltip: 'View QR',
                      icon: Icon(
                        Icons.qr_code_2_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: p.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.visibility_rounded,
                      label: 'View',
                      onTap: onView,
                      color: p.isDark ? AppColors.info : AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      onTap: onEdit,
                      color: p.isDark
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFB45309),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF1F2F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: p.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final bg = color.withValues(alpha: p.isDark ? 0.16 : 0.12);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
