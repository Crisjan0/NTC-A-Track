import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/update_dialog.dart';
import '../auth/login_screen.dart';

/// Admin profile: account details + logout + app update check.
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final session = SessionService.instance.current;
    final username = session?.username ?? 'admin';

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Profile',
            subtitle: 'Account settings',
            icon: Icons.person_rounded,
            trailing: IconButton(
              onPressed: () => showUpdateDialog(context),
              tooltip: 'Check for app updates',
              icon: const Icon(
                Icons.system_update_rounded,
                color: Colors.white,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Identity card.
                  GlassPanel(
                    radius: kCardRadius,
                    blur: 26,
                    strong: true,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            gradient: AppGradients.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full system access',
                          style: TextStyle(
                            fontSize: 13,
                            color: p.textSecondary,
                          ),
                        ),
                        Divider(
                          height: 32,
                          color: p.isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        _ProfileRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Username',
                          value: username,
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
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.35),
                        ),
                        backgroundColor:
                            AppColors.danger.withValues(alpha: 0.1),
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
    final p = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: p.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
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
