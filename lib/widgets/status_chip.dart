import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// Colored translucent pill showing PRESENT / ABSENT status.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final isPresent = status.toUpperCase() == AttendanceStatus.present;
    final base = isPresent ? AppColors.success : AppColors.danger;
    final color = p.isDark
        ? Color.lerp(base, Colors.white, 0.3)!
        : base;
    final bg = base.withValues(alpha: p.isDark ? 0.18 : 0.12);
    final icon = isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded;

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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isPresent ? 'PRESENT' : 'ABSENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
