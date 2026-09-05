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
import 'role_selection_screen.dart';

/// Shared login screen; fields adapt to the selected role.
class LoginScreen extends StatefulWidget {
  final String role; // 'admin' | 'student'

  const LoginScreen({super.key, required this.role});

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

  bool get _isAdmin => widget.role == 'admin';

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
      if (_isAdmin) {
        await AuthService.instance.loginAdmin(
          _identifierController.text,
          _passwordController.text,
        );
      } else {
        await AuthService.instance.loginStudent(
          _identifierController.text,
          _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              _isAdmin ? const AdminShell() : const StudentShell(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const RoleSelectionScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(
                                  _isAdmin
                                      ? Icons.admin_panel_settings_rounded
                                      : Icons.school_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_isAdmin ? 'Admin' : 'Student'} Login',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 10,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isAdmin
                                          ? 'Sign in to manage the system'
                                          : 'Sign in with your Student ID',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _identifierController,
                      textInputAction: TextInputAction.next,
                      autofillHints: _isAdmin
                          ? const [AutofillHints.username]
                          : null,
                      validator: _isAdmin
                          ? Validators.username
                          : Validators.studentId,
                      decoration: InputDecoration(
                        labelText: _isAdmin ? 'Username' : 'Student ID',
                        hintText:
                            _isAdmin ? 'e.g. admin' : 'e.g. 2026-0001',
                        prefixIcon: Icon(
                          _isAdmin
                              ? Icons.person_outline_rounded
                              : Icons.badge_outlined,
                        ),
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
                    _DemoHint(role: widget.role),
                  ],
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
  final String role;

  const _DemoHint({required this.role});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = role == 'admin';
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
            isAdmin
                ? 'Username: ${DemoCredentials.adminUsername}\nPassword: ${DemoCredentials.adminPassword}'
                : 'Student ID: 2026-0001\nPassword: ${DemoCredentials.studentPassword}\n(Other seeded IDs: 2026-0002 … 2026-0005)',
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
