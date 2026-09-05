import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import 'login_screen.dart';

/// Lets the user pick which role they are logging in as.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);

    return GlassScaffold(
      animated: true,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            GlassPanel(
              radius: 26,
              blur: 26,
              strong: true,
              showSheen: true,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 76,
                  height: 76,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Attendance',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Simple, clear, and ready to scan',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Who is signing in?',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RoleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Admin',
                    subtitle: 'Manage students, scan QR codes\nand view attendance records',
                    onTap: () => _go(context, 'admin'),
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    icon: Icons.person_rounded,
                    title: 'Student',
                    subtitle: 'View your QR code and\npersonal attendance history',
                    onTap: () => _go(context, 'student'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Local demo database · No internet required',
              style: TextStyle(
                color: p.textSecondary.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String role) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, _) => LoginScreen(role: role),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: 22,
      blur: 26,
      strong: true,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
