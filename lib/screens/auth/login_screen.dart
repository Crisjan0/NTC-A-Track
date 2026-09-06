import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/login_rate_limiter.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
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

  // Login rate limiting: after 5 wrong passwords the identifier is locked
  // for 5 minutes with a live countdown.
  Timer? _lockTimer;
  int _lockSeconds = 0;
  String? _lockedIdentifier;
  int _attemptsLeft = LoginRateLimiter.maxAttempts;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Starts (or restarts) the 5-minute lock countdown.
  void _startCountdown(int seconds) {
    _lockTimer?.cancel();
    setState(() {
      _lockSeconds = seconds;
      _attemptsLeft = 0;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _lockSeconds = _lockSeconds - 1);
      if (_lockSeconds <= 0) {
        timer.cancel();
        setState(() {
          _lockedIdentifier = null;
          _attemptsLeft = LoginRateLimiter.maxAttempts;
        });
      }
    });
  }

  /// Re-checks the persisted lock when the screen opens or the identifier
  /// changes, so a lock that survived an app restart is still enforced.
  Future<void> _checkLock() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) return;
    final remaining =
        await LoginRateLimiter.instance.remainingLockSeconds(identifier);
    if (!mounted) return;
    if (remaining > 0) {
      _lockedIdentifier = identifier.toLowerCase();
      _startCountdown(remaining);
    }
  }

  void _onIdentifierChanged(String value) {
    final normalized = value.trim().toLowerCase();
    if (_lockedIdentifier != null && _lockedIdentifier != normalized) {
      // A different account was typed — drop the previous lock.
      _lockTimer?.cancel();
      setState(() {
        _lockedIdentifier = null;
        _lockSeconds = 0;
        _attemptsLeft = LoginRateLimiter.maxAttempts;
      });
    }
    _checkLock();
  }

  Future<void> _submit() async {
    if (_lockSeconds > 0) return;
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
    } on RateLimitException catch (e) {
      // 5th wrong password — lock the form with a 5-minute countdown.
      if (!mounted) return;
      _lockedIdentifier =
          _identifierController.text.trim().toLowerCase();
      _startCountdown(e.remainingSeconds);
      setState(() => _error = null);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      // Show how many attempts are left before the lock kicks in.
      final left = await LoginRateLimiter.instance
          .remainingAttempts(_identifierController.text.trim());
      if (mounted) setState(() => _attemptsLeft = left);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      animated: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.94, end: 1),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 390,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFD6D6D6)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Image.asset(
                              'assets/icon/ntc-icon.png',
                              width: 130,
                              height: 130,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NTC A-Track',
                            style: GoogleFonts.manrope(
                              color: Color(0xFF202020),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Attendance Tracking System',
                            style: GoogleFonts.manrope(
                              color: Color(0xFF777777),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'SIGN IN TO CONTINUE',
                                  style: GoogleFonts.manrope(
                                    color: Color(0xFF888888),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            controller: _identifierController,
                            hintText: 'Username or Student ID',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            enabled: _lockSeconds == 0,
                            onChanged: _onIdentifierChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username or Student ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            enabled: _lockSeconds == 0,
                            textInputAction: TextInputAction.done,
                            validator: Validators.password,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: const Color(0xFF777777),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: Color(0xFF555555),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_lockSeconds > 0) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Color(0xFFB45309),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Too many failed attempts. Try again in '
                                      '${_formatCountdown(_lockSeconds)}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFFB45309),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_attemptsLeft <
                              LoginRateLimiter.maxAttempts) ...[
                            const SizedBox(height: 14),
                            Text(
                              _attemptsLeft == 1
                                  ? 'Last attempt — account locks for 5 '
                                      'minutes after this'
                                  : '$_attemptsLeft attempts remaining before '
                                      'temporary lock',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: const Color(0xFFB45309),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          CustomButton(
                            label: _lockSeconds > 0 ? 'Locked' : 'Login',
                            icon: Icons.login_rounded,
                            width: 150,
                            loading: _loading,
                            onPressed: (_loading || _lockSeconds > 0)
                                ? null
                                : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.manrope(
        color: Color(0xFF202020),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.manrope(
          color: Color(0xFF777777),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.manrope(
          color: Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF777777), size: 21),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFF666666), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFF777777)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFF555555), width: 1.6),
        ),
      ),
    );
  }
}
