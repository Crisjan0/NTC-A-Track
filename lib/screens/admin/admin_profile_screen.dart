import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/check_update_card.dart';
import '../../widgets/gradient_header.dart';
import '../auth/login_screen.dart';

/// Admin profile: account details + logout.
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
          const GradientHeader(
            title: 'Profile',
            subtitle: 'Account settings',
            icon: Icons.person_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
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
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x554F46E5),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
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
                        _ProfileRow(
                          icon: Icons.admin_panel_settings_rounded,
                          label: 'Role',
                          value: 'Admin',
                        ),
                        _ProfileRow(
                          icon: Icons.storage_rounded,
                          label: 'Database',
                          value: 'Local SQLite (demo)',
                        ),
                        _ProfileRow(
                          icon: Icons.lock_outline_rounded,
                          label: 'Security',
                          value: 'Hashed passwords',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CheckUpdateCard(),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
