import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_shell.dart';
import 'services/session_service.dart';
import 'utils/app_theme.dart';
import 'widgets/glass_panel.dart';
import 'widgets/liquid_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Launch screen: restores the saved session, then routes to the right
/// dashboard (or the login screen when logged out).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _fade.forward();
    _route();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _route() async {
    await SessionService.instance.init();
    if (!mounted) return;

    final session = SessionService.instance.current;
    final Widget home = session == null
        ? const LoginScreen()  // Go directly to login, no role selection
        : session.isAdmin
            ? const AdminShell()
            : const StudentShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: home),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return LiquidBackground(
      animated: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassPanel(
                    radius: 30,
                    blur: 30,
                    strong: true,
                    showSheen: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 78,
                        height: 78,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Attendance',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simple, clear, and ready to scan',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
