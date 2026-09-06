import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../widgets/glass_nav_bar.dart';
import '../../widgets/glass_scaffold.dart';
import '../auth/role_selection_screen.dart';
import 'admin_dashboard.dart';
import 'admin_profile_screen.dart';
import 'attendance_management_screen.dart';
import 'qr_scanner_screen.dart';
import 'student_management_screen.dart';
import 'user_management_screen.dart';

/// Admin's main scaffold: bottom navigation across all admin pages.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _index = 0;

  /// Lets child pages (e.g. dashboard quick actions) switch tabs.
  void switchTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // Defense in depth: never allow a non-admin into the admin shell.
    final session = SessionService.instance.current;
    if (session == null || !session.isAdmin) {
      return const RoleSelectionScreen();
    }

    final pages = const [
      AdminDashboard(),
      StudentManagementScreen(),
      UserManagementScreen(),
      QrScanLandingPage(),
      AttendanceManagementScreen(),
      AdminProfileScreen(),
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
            icon: Icons.group_outlined,
            selectedIcon: Icons.group_rounded,
            label: 'Students',
          ),
          GlassNavDestination(
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings_rounded,
            label: 'Users',
          ),
          GlassNavDestination(
            icon: Icons.qr_code_scanner_rounded,
            selectedIcon: Icons.qr_code_scanner_rounded,
            label: 'Scan',
            accent: true,
          ),
          GlassNavDestination(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
            label: 'Attendance',
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
