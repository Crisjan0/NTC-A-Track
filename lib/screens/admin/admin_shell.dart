import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../widgets/glass_nav_bar.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../auth/role_selection_screen.dart';
import 'admin_dashboard.dart';
import 'admin_profile_screen.dart';
import 'attendance_management_screen.dart';
import 'qr_scanner_screen.dart';
import 'student_management_screen.dart';
import 'user_management_screen.dart';

/// Admin's main scaffold: hamburger navigation across all admin pages.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _index = 0;

  /// Lets child pages (e.g. dashboard quick actions) switch tabs.
  void switchTo(int index) => setState(() => _index = index);

  void _openMenu(List<GlassNavDestination> destinations) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: GlassPanel(
          radius: 28,
          blur: 40,
          strong: true,
          borderWidth: 1,
          showSheen: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < destinations.length; i++)
                ListTile(
                  leading: Icon(
                    i == _index
                        ? (destinations[i].selectedIcon ?? destinations[i].icon)
                        : destinations[i].icon,
                  ),
                  title: Text(destinations[i].label),
                  selected: i == _index,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _index = i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

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

    const destinations = [
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
    ];

    return GlassScaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: GlassPanel(
          radius: 30,
          blur: 40,
          strong: true,
          borderWidth: 1,
          showSheen: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: IconButton(
            tooltip: 'Open admin menu',
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => _openMenu(destinations),
          ),
        ),
      ),
    );
  }
}
