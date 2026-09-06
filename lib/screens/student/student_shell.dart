import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../widgets/glass_nav_bar.dart';
import '../../widgets/glass_scaffold.dart';
import '../auth/role_selection_screen.dart';
import 'my_attendance_screen.dart';
import 'my_qr_code_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_profile_screen.dart';

/// Student's main scaffold: bottom navigation across student pages.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => StudentShellState();
}

class StudentShellState extends State<StudentShell> {
  int _index = 0;

  /// Lets child pages switch tabs.
  void switchTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // Defense in depth: only students may enter this shell.
    final session = SessionService.instance.current;
    if (session == null || !session.isStudent) {
      return const RoleSelectionScreen();
    }

    final pages = [
      const StudentDashboardScreen(),
      const MyQrCodeScreen(),
      const MyAttendanceScreen(),
      const StudentProfileScreen(),
    ];

    return GlassScaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          GlassNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          GlassNavDestination(
            icon: Icons.qr_code_2_outlined,
            selectedIcon: Icons.qr_code_2_rounded,
            label: 'My QR',
          ),
          GlassNavDestination(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
            label: 'My Attendance',
          ),
          GlassNavDestination(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
