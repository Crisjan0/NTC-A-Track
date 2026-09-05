import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Circular avatar showing a person's initials on the brand gradient,
/// finished with a soft glass ring.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const InitialsAvatar({
    super.key,
    required this.initials,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.9);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
