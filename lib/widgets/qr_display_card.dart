import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/student_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'avatar.dart';
import 'glass_panel.dart';

/// A polished liquid-glass card showing a student's QR code alongside their
/// details. The QR plate itself stays white with dark modules so it always
/// scans cleanly, whatever the theme.
class QrDisplayCard extends StatelessWidget {
  final Student student;

  const QrDisplayCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);

    return GlassPanel(
      radius: kCardRadius + 2,
      blur: 30,
      strong: true,
      borderWidth: 1,
      child: Column(
        children: [
          // Gradient banner with name + avatar.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 46),
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryDeep,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(kCardRadius + 1),
              ),
            ),
            child: Column(
              children: [
                InitialsAvatar(initials: student.initials, radius: 26),
                const SizedBox(height: 12),
                Text(
                  student.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.studentId,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // QR code overlapping the banner (opaque plate for contrast).
          Transform.translate(
            offset: const Offset(0, -32),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: p.isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: p.isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: student.studentId,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1E1B2E),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1E1B2E),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Show this QR code to the admin to record attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.menu_book_rounded,
                    label: 'Course',
                    value: student.course,
                  ),
                  _DetailRow(
                    icon: Icons.grade_rounded,
                    label: 'Year Level',
                    value: student.yearLevel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: p.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
