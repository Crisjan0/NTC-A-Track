import 'dart:math' as math;
import 'dart:ui';
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

  /// Lets child pages switch tabs.
  void switchTo(int index) => setState(() => _index = index);

  void _openMenu(List<GlassNavDestination> destinations) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close admin menu',
      barrierColor: Colors.transparent, // Transparent para BackdropFilter ang mo-handle sa hanap
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => _RadialAdminMenu(
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
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
            alignment: Alignment.bottomCenter,
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
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassPanel(
              radius: 30,
              blur: 24,
              strong: true,
              borderWidth: 1,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Open admin menu',
                icon: _HamburgerIcon(
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _openMenu(destinations),
              ),
            ),
          ],
        ),
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
      width: 26,
      height: 18,
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
      width: 26,
      height: 3.2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _RadialAdminMenu extends StatelessWidget {
  const _RadialAdminMenu({
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
        fit: StackFit.expand,
        children: [
          // Frosted glass background effect (mo-hanap ang background)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Menu Buttons
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = destinations.length;
                final centerX = constraints.maxWidth / 2;

                final radius = (constraints.maxWidth * 0.44).clamp(160.0, 200.0);
                const bottomOrigin = 38.0;
                const buttonWidth = 62.0;

                const startAngle = 8.0 * (math.pi / 180.0);
                const endAngle = 172.0 * (math.pi / 180.0);
                final step = (endAngle - startAngle) / (count - 1);

                return Stack(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      () {
                        final angle = startAngle + (i * step);
                        final dx = -radius * math.cos(angle);
                        final dy = bottomOrigin + (radius * math.sin(angle));

                        return Positioned(
                          left: centerX + dx - (buttonWidth / 2),
                          bottom: dy,
                          child: SizedBox(
                            width: buttonWidth,
                            child: _RadialMenuButton(
                              destination: destinations[i],
                              selected: i == selectedIndex,
                              color: primary,
                              onTap: () => onSelected(i),
                            ),
                          ),
                        );
                      }(),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialMenuButton extends StatelessWidget {
  const _RadialMenuButton({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: selected ? color : Colors.white.withValues(alpha: 0.95),
          shape: const CircleBorder(),
          elevation: selected ? 8 : 3,
          shadowColor: color.withValues(alpha: 0.28),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                selected
                    ? (destination.selectedIcon ?? destination.icon)
                    : destination.icon,
                color: selected ? Colors.white : color.withValues(alpha: 0.85),
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? color : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}