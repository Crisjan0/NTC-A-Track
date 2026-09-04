import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Colored pill showing PRESENT / ABSENT status.
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPresent = status.toUpperCase() == AttendanceStatus.present;
    final color = isPresent ? AppColors.success : AppColors.danger;
    final bg = isPresent ? AppColors.successLight : AppColors.dangerLight;
    final icon = isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
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