import 'package:flutter/material.dart';

import '../../services/session_service.dart';
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

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'My QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}