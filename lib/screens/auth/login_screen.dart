import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../admin/admin_shell.dart';
import '../student/student_shell.dart';

/// Unified login screen - auto-detects role (Admin or Student) from credentials
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Auto-detect role from identifier
      final session = await AuthService.instance.loginAuto(
        _identifierController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      
      // Navigate to appropriate dashboard based on detected role
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              session.isAdmin ? const AdminShell() : const StudentShell(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);

    return GlassScaffold(
      animated: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Floating gradient glass header with the back action.
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: GlassPanel(
                  radius: 26,
                  blur: 30,
                  strong: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary
                              .withValues(alpha: p.isDark ? 0.75 : 0.85),
                          AppColors.primaryDark
                              .withValues(alpha: p.isDark ? 0.6 : 0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GlassPanel(
                            radius: 16,
                            blur: 20,
                            showSheen: true,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 64,
                                height: 64,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'NTC A-Track',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Attendance Tracking System',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 350,  // Limit form width for centered layout
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    TextFormField(
                      controller: _identifierController,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username or Student ID is required';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Username or Student ID',
                        hintText: 'e.g. admin or 2026-0001',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      GlassPanel(
                        radius: 14,
                        blur: 14,
                        borderWidth: 0.8,
                        showSheen: false,
                        fill: AppColors.danger,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'Login',
                      icon: Icons.login_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 20),
                    const _DemoHint(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint();

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 16,
      blur: 18,
      borderWidth: 0.8,
      showSheen: false,
      fill: p.isDark
          ? Colors.white.withValues(alpha: 0.09)
          : Colors.white.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Demo credentials',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Admin:\nUsername: ${DemoCredentials.adminUsername}\nPassword: ${DemoCredentials.adminPassword}\n\n'
            'Student:\nStudent ID: 2026-0001\nPassword: ${DemoCredentials.studentPassword}\n'
            '(Other IDs: 2026-0002 … 2026-0005)',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
