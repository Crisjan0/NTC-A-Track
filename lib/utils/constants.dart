import 'package:flutter/material.dart';

/// Brightness-aware "liquid glass" palette.
///
/// Every screen draws over a colorful wallpaper (see [LiquidBackground]) and
/// content sits on frosted, translucent glass panels. The palette carries the
/// fill, text and highlight colors for light and dark appearances; pick one
/// with `AppTheme.paletteOf(context)`.
class GlassPalette {
  const GlassPalette({
    required this.brightness,
    required this.wallpaperTop,
    required this.wallpaperBottom,
    required this.blobColors,
    required this.blobOpacity,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassFillSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderStroke,
    required this.hairline,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.scrim,
  });

  final Brightness brightness;

  /// Wallpaper base gradient (behind the frosted glass).
  final Color wallpaperTop;
  final Color wallpaperBottom;

  /// Vivid color blobs painted on the wallpaper behind the glass.
  final List<Color> blobColors;
  final double blobOpacity;

  /// Frosted glass panel fills.
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassFillSoft;

  final Color textPrimary;
  final Color textSecondary;

  /// Subtle outer stroke of a glass panel.
  final Color borderStroke;

  /// Bright edge (top) highlight used by panels and the tab bar.
  final Color hairline;

  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color scrim;

  bool get isDark => brightness == Brightness.dark;

  static const GlassPalette light = GlassPalette(
    brightness: Brightness.light,
    wallpaperTop: Color(0xFFEFF2FF),
    wallpaperBottom: Color(0xFFFBF4FF),
    blobColors: [
      Color(0xFF4F46E5),
      Color(0xFF8B5CF6),
      Color(0xFF38BDF8),
      Color(0xFFEC4899),
      Color(0xFF22D3EE),
    ],
    blobOpacity: 0.34,
    glassFill: Color(0xB8FFFFFF), // ~72% white
    glassFillStrong: Color(0xD9FFFFFF), // ~85% white
    glassFillSoft: Color(0x8AFFFFFF), // ~54% white
    textPrimary: Color(0xFF1B1833),
    textSecondary: Color(0xFF625E86),
    borderStroke: Color(0x14000000), // faint black hairline
    hairline: Color(0xE6FFFFFF), // bright white top edge
    primaryContainer: Color(0xFFE5E8FF),
    onPrimaryContainer: Color(0xFF2A2560),
    scrim: Color(0x33000000),
  );

  static const GlassPalette dark = GlassPalette(
    brightness: Brightness.dark,
    wallpaperTop: Color(0xFF100E22),
    wallpaperBottom: Color(0xFF231238),
    blobColors: [
      Color(0xFF6366F1),
      Color(0xFFA855F7),
      Color(0xFF0EA5E9),
      Color(0xFFF472B6),
      Color(0xFF14B8A6),
    ],
    blobOpacity: 0.55,
    glassFill: Color(0x1FFFFFFF), // ~12% white
    glassFillStrong: Color(0x33FFFFFF), // ~20% white
    glassFillSoft: Color(0x14000000), // darker scrim-tint panel
    textPrimary: Color(0xFFF4F2FF),
    textSecondary: Color(0xFFB7B3D4),
    borderStroke: Color(0x33FFFFFF),
    hairline: Color(0x59FFFFFF),
    primaryContainer: Color(0xFF37317F),
    onPrimaryContainer: Color(0xFFDCD9FF),
    scrim: Color(0x66000000),
  );
}

/// App-wide constants: colors, spacing, labels.
class AppColors {
  AppColors._();

  // Vivid accent palette — shared by light and dark appearances. These read
  // well on glass in both modes.
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color violet = Color(0xFF7C3AED);
  static const Color indigoLight = Color(0xFFEEF2FF);
  static const Color violetLight = Color(0xFFF5F3FF);

  static const Color background = Color(0xFFF4F5FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
}

/// Brand gradients used on headers, buttons and accent elements.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
  );

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  static const LinearGradient info = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
  );
}

/// Available course choices for the demo.
const List<String> kCourses = [
  'BS Information Technology',
  'BS Computer Science',
  'BS Accountancy',
  'BS Business Administration',
  'BS Nursing',
  'BS Engineering',
];

/// Available year level choices for the demo.
const List<String> kYearLevels = [
  '1st Year',
  '2nd Year',
  '3rd Year',
  '4th Year',
];

/// Attendance status values stored in the database.
class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'PRESENT';
  static const String absent = 'ABSENT';
}

/// Attendance flow options for an event.
class EventFlowType {
  EventFlowType._();

  /// One scan per student per day marks attendance (default).
  static const String oneTime = 'ONE_TIME';

  /// AM + PM sessions, each with a Time In and a Time Out scan.
  static const String timeInOut = 'TIME_IN_OUT';
}

/// What a single attendance record represents. For [EventFlowType.oneTime]
/// events every record is [present]; for [EventFlowType.timeInOut] events
/// records are one of the four AM/PM check-in/check-out combinations.
class CheckType {
  CheckType._();

  static const String present = 'PRESENT';
  static const String amIn = 'AM_IN';
  static const String amOut = 'AM_OUT';
  static const String pmIn = 'PM_IN';
  static const String pmOut = 'PM_OUT';

  static const List<String> all = [present, amIn, amOut, pmIn, pmOut];

  /// "AM Time In" / "PM Time Out" style labels.
  static String label(String checkType) => switch (checkType) {
        amIn => 'AM Time In',
        amOut => 'AM Time Out',
        pmIn => 'PM Time In',
        pmOut => 'PM Time Out',
        _ => 'Present',
      };
}

/// Default demo credentials (seeded on first run).
class DemoCredentials {
  DemoCredentials._();

  static const String adminUsername = 'admin';
  static const String adminPassword = 'admin123';
  static const String studentPassword = 'student123';
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

const double kCardRadius = 20;
const double kFieldRadius = 16;
const double kButtonRadius = 16;
