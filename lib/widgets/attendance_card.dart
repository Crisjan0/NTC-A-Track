import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'glass_panel.dart';
import 'status_chip.dart';

/// A frosted glass row showing a single attendance record.
class AttendanceCard extends StatelessWidget {
  final Attendance record;
  final bool showStudent;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.record,
    this.showStudent = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;

    return GlassPanel(
      radius: 18,
      blur: 22,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
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
                  '${record.date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.isDark ? p.onPrimaryContainer : AppColors.primary,
                  ),
                ),
                Text(
                  _monthAbbr(record.date),
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
                if (showStudent && record.studentName != null) ...[
                  Text(
                    record.studentName!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  if (record.course != null || record.yearLevel != null)
                    Text(
                      [record.course, record.yearLevel]
                          .whereType<String>()
                          .join(' · '),
                      style: TextStyle(
                        fontSize: 11,
                        color: p.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: p.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        Formatters.time(record.time),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.badge_rounded, size: 14, color: p.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        record.studentId,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (record.eventName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 13, color: scheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            record.eventName!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          record.checkType == CheckType.present
              ? StatusChip(status: record.status)
              : _CheckChip(checkType: record.checkType),
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

/// Pill showing what a Time In/Out record is (e.g. "AM TIME IN").
class _CheckChip extends StatelessWidget {
  final String checkType;

  const _CheckChip({required this.checkType});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final isIn = checkType.endsWith('_IN');
    final base = isIn ? AppColors.info : AppColors.warning;
    final color = p.isDark ? Color.lerp(base, Colors.white, 0.3)! : base;
    final bg = base.withValues(alpha: p.isDark ? 0.18 : 0.12);
    final icon = isIn ? Icons.login_rounded : Icons.logout_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            CheckType.label(checkType).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
