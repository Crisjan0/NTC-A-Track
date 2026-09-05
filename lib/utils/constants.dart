import 'package:flutter/material.dart';

/// Navy tonal scale (50–900), derived from the app icon's navy. This is the
/// single source of truth for the primary brand hue: `c700` is the default
/// accent, `c900` the deep navy used in gradients and headers.
class BrandNavy {
  BrandNavy._();

  static const Color c50 = Color(0xFFEEF3FF);
  static const Color c100 = Color(0xFFDCE7FF);
  static const Color c200 = Color(0xFFB7C7F9);
  static const Color c300 = Color(0xFF8AA4F2);
  static const Color c400 = Color(0xFF5D7FE9);
  static const Color c500 = Color(0xFF3A5CDB);
  static const Color c600 = Color(0xFF2547BF);
  static const Color c700 = Color(0xFF1E40AF); // default primary
  static const Color c800 = Color(0xFF143497);
  static const Color c900 = Color(0xFF002080); // icon navy
  static const Color c950 = Color(0xFF00155C);

  static const List<Color> scale = [
    c50, c100, c200, c300, c400, c500, c600, c700, c800, c900, c950,
  ];
}

/// Orange tonal scale (50–900), derived from the app icon's orange. Used as
/// the secondary accent behind navy.
class BrandOrange {
  BrandOrange._();

  static const Color c50 = Color(0xFFFFF4EA);
  static const Color c100 = Color(0xFFFFE7D2);
  static const Color c200 = Color(0xFFFFD1A6);
  static const Color c300 = Color(0xFFFFB575);
  static const Color c400 = Color(0xFFFB913C);
  static const Color c500 = Color(0xFFF2700E);
  static const Color c600 = Color(0xFFE06000); // icon orange (default)
  static const Color c700 = Color(0xFFB84E00);
  static const Color c800 = Color(0xFF8F3C00);
  static const Color c900 = Color(0xFF6E2E00);
  static const Color c950 = Color(0xFF4A1F00);

  static const List<Color> scale = [
    c50, c100, c200, c300, c400, c500, c600, c700, c800, c900, c950,
  ];
}

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
    wallpaperTop: Color(0xFFEFF2FB),
    wallpaperBottom: Color(0xFFFDF4EC),
    blobColors: [
      BrandNavy.c700,
      BrandNavy.c500,
      BrandNavy.c300,
      BrandOrange.c600,
      BrandOrange.c400,
    ],
    blobOpacity: 0.3,
    glassFill: Color(0xB8FFFFFF), // ~72% white
    glassFillStrong: Color(0xD9FFFFFF), // ~85% white
    glassFillSoft: Color(0x8AFFFFFF), // ~54% white
    textPrimary: Color(0xFF17203F),
    textSecondary: Color(0xFF5A647E),
    borderStroke: Color(0x14000000), // faint black hairline
    hairline: Color(0xE6FFFFFF), // bright white top edge
    primaryContainer: BrandNavy.c100,
    onPrimaryContainer: BrandNavy.c900,
    scrim: Color(0x33000000),
  );

  static const GlassPalette dark = GlassPalette(
    brightness: Brightness.dark,
    wallpaperTop: Color(0xFF0D1026),
    wallpaperBottom: Color(0xFF25192E),
    blobColors: [
      BrandNavy.c400,
      BrandNavy.c500,
      BrandNavy.c700,
      BrandOrange.c500,
      BrandOrange.c300,
    ],
    blobOpacity: 0.5,
    glassFill: Color(0x1FFFFFFF), // ~12% white
    glassFillStrong: Color(0x33FFFFFF), // ~20% white
    glassFillSoft: Color(0x14000000), // darker scrim-tint panel
    textPrimary: Color(0xFFF2F4FF),
    textSecondary: Color(0xFFB4BBD9),
    borderStroke: Color(0x33FFFFFF),
    hairline: Color(0x59FFFFFF),
    primaryContainer: BrandNavy.c800,
    onPrimaryContainer: BrandNavy.c200,
    scrim: Color(0x66000000),
  );
}

/// App-wide constants: colors, spacing, labels.
///
/// Brand colors are aliases into [BrandNavy]/[BrandOrange] so the app never
/// hard-codes a brand hex twice — re-tone the scales and everything follows.
class AppColors {
  AppColors._();

  // ---- Brand: navy (primary) ----
  static const Color primary = BrandNavy.c700;
  static const Color primaryDark = BrandNavy.c900;
  static const Color navyLight = BrandNavy.c100;

  // ---- Brand: orange (secondary) ----
  static const Color orange = BrandOrange.c600;
  static const Color orangeLight = BrandOrange.c100;

  // ---- Legacy neutral light-mode values (kept for compat; new code should
  // read text colors from the active GlassPalette instead). ----
  static const Color background = Color(0xFFF4F5FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // ---- Semantic status colors (independent of the brand scales). ----
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  /// Brighter green used for success text/icons on dark glass.
  static const Color successBright = Color(0xFF34D399);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  /// Amber text variant for dark mode.
  static const Color warningBright = Color(0xFFFBBF24);
  /// Deep amber text variant for light mode.
  static const Color warningDark = Color(0xFFB45309);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  /// iOS-style switch green (platform tint, not brand).
  static const Color switchGreen = Color(0xFF34C759);
}

/// Brand gradients used on headers, buttons and accent elements. Like
/// [AppColors], these are built from the navy/orange scales.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandNavy.c700, BrandNavy.c500],
  );

  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandNavy.c900, BrandNavy.c700],
  );

  static const LinearGradient orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BrandOrange.c400, BrandOrange.c600],
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
