import 'dart:ui';
import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../widgets/glass_nav_bar.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';
import 'admin_profile_screen.dart';
import 'attendance_management_screen.dart';
import 'qr_scanner_screen.dart';
import 'student_management_screen.dart';
import 'manage_courses_screen.dart';
import 'user_management_screen.dart';

/// Admin's main scaffold: hamburger navigation across all admin pages.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _index = 0;

  /// Lets child pages switch tabs.
  void switchTo(int index) => setState(() => _index = index);

  void _openMenu(List<GlassNavDestination> destinations) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close admin menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => _SwipeableAdminDock(
        destinations: destinations,
        selectedIndex: _index,
        onSelected: (index) {
          Navigator.of(context).pop();
          setState(() => _index = index);
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance.current;
    if (session == null || !session.isAdmin) {
      return const LoginScreen();
    }

    final pages = const [
      AdminDashboard(),
      StudentManagementScreen(),
      ManageCoursesScreen(),
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
        icon: Icons.school_outlined,
        selectedIcon: Icons.school_rounded,
        label: 'Courses',
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Content sa page
          Positioned.fill(
            child: IndexedStack(index: _index, children: pages),
          ),

          // Kana ra gyung pill/capsule button ang maglutaw sa ubos
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openMenu(destinations),
                  borderRadius: BorderRadius.circular(35),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _HamburgerIcon(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _line(),
          _line(),
          _line(),
        ],
      ),
    );
  }

  Widget _line() {
    return Container(
      width: 24,
      height: 2.8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SwipeableAdminDock extends StatelessWidget {
  const _SwipeableAdminDock({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlassNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassPanel(
                    radius: 36,
                    blur: 30,
                    strong: true,
                    borderWidth: 1.2,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < destinations.length; i++) ...[
                            _DockItem(
                              destination: destinations[i],
                              selected: i == selectedIndex,
                              color: primary,
                              onTap: () => onSelected(i),
                            ),
                            if (i != destinations.length - 1)
                              const SizedBox(width: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: Colors.black87),
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

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: selected ? color : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? color.withOpacity(0.38)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              selected
                  ? (destination.selectedIcon ?? destination.icon)
                  : destination.icon,
              color: selected ? Colors.white : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              destination.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? color : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}