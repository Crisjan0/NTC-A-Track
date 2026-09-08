import 'package:flutter/material.dart';

/// Minimalist Grayscale Palette - FIXED COLORS (never changes)
class BrandNavy {
  BrandNavy._();

  static const Color c50 = Color(0xFFF5F5F5);  // Lightest gray
  static const Color c100 = Color(0xFFEEEEEE);
  static const Color c200 = Color(0xFFE0E0E0);
  static const Color c300 = Color(0xFFCCCCCC);
  static const Color c400 = Color(0xFFAAAAAA);
  static const Color c500 = Color(0xFF808080);  // Medium gray
  static const Color c600 = Color(0xFF666666);
  static const Color c700 = Color(0xFF555555);
  static const Color c800 = Color(0xFF333333);
  static const Color c900 = Color(0xFF1A1A1A);
  static const Color c950 = Color(0xFF0D0D0D);  // Darkest gray

  static const List<Color> scale = [
    c50, c100, c200, c300, c400, c500, c600, c700, c800, c900, c950,
  ];
}


/// Minimalist Grayscale Palette Secondary - FIXED COLORS (never changes)
class BrandOrange {
  BrandOrange._();

  static const Color c50 = Color(0xFFFAFAFA);
  static const Color c100 = Color(0xFFF5F5F5);
  static const Color c200 = Color(0xFFEEEEEE);
  static const Color c300 = Color(0xFFE0E0E0);
  static const Color c400 = Color(0xFFC0C0C0);
  static const Color c500 = Color(0xFF999999);
  static const Color c600 = Color(0xFF808080);
  static const Color c700 = Color(0xFF666666);
  static const Color c800 = Color(0xFF444444);
  static const Color c900 = Color(0xFF262626);
  static const Color c950 = Color(0xFF0D0D0D);

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

  /// FIXED MINIMALIST PALETTE - Always the same grayscale, never changes
  static const GlassPalette fixed = GlassPalette(
    brightness: Brightness.light,
    wallpaperTop: Color(0xFFFFFFFF),  // White
    wallpaperBottom: Color(0xFFFFFFFF),  // White
    blobColors: [
      Color(0xFFE0E0E0),  // Light gray blobs
      Color(0xFFCCCCCC),
      Color(0xFFC0C0C0),
      Color(0xFFB0B0B0),
      Color(0xFFA0A0A0),
    ],
    blobOpacity: 0.15,  // Subtle blobs
    glassFill: Color(0xFFF5F5F5),  // Very light gray
    glassFillStrong: Color(0xFFEEEEEE),  // Light gray
    glassFillSoft: Color(0xFFFAFAFA),  // Lightest gray
    textPrimary: Color(0xFF1A1A1A),  // Dark gray text
    textSecondary: Color(0xFF666666),  // Medium gray text
    borderStroke: Color(0xFFCCCCCC),  // Light gray border
    hairline: Color(0xFFFFFFFF),  // White top edge
    primaryContainer: Color(0xFFE0E0E0),  // Light gray
    onPrimaryContainer: Color(0xFF333333),  // Dark gray
    scrim: Color(0x33000000),  // Semi-transparent black
  );
}

/// App-wide constants: colors, spacing, labels.
/// ALL COLORS ARE FIXED MINIMALIST GRAYSCALE - Never changes!
class AppColors {
  AppColors._();

  // ---- Fixed Minimalist: Grayscale primary ----
  static const Color primary = Color(0xFF666666);  // Medium-dark gray
  static const Color primaryDark = Color(0xFF333333);  // Dark gray
  static const Color navyLight = Color(0xFFEEEEEE);  // Light gray

  // ---- Fixed Minimalist: Grayscale secondary ----
  static const Color orange = Color(0xFF999999);  // Medium gray
  static const Color orangeLight = Color(0xFFCCCCCC);  // Light gray

  // ---- Fixed light-mode neutral values ----
  static const Color background = Color(0xFFFFFFFF);  // White
  static const Color surface = Color(0xFFFFFFFF);  // White
  static const Color textPrimary = Color(0xFF1A1A1A);  // Dark text
  static const Color textSecondary = Color(0xFF666666);  // Medium gray text
  static const Color border = Color(0xFFCCCCCC);  // Light border

  // ---- Semantic status colors (kept for alerts/notifications) ----
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successBright = Color(0xFF34D399);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningBright = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFB45309);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  /// iOS-style switch green (platform tint, not brand).
  static const Color switchGreen = Color(0xFF34C759);
}

/// Brand gradients - FIXED MINIMALIST GRAYSCALE
/// All gradients use gray tones for a clean, minimalist look
class AppGradients {
  AppGradients._();

  /// Fixed grayscale primary gradient
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF808080), Color(0xFF666666)],  // Gray gradient
  );

  /// Fixed grayscale deep gradient
  static const LinearGradient primaryDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF555555)],  // Dark gray gradient
  );

  /// Fixed grayscale secondary gradient
  static const LinearGradient orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF999999), Color(0xFF666666)],  // Gray gradient
  );

  /// Fixed success gradient (kept for alerts)
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
  );

  /// Fixed danger gradient (kept for alerts)
  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), Color(0xFFEF4444)],
  );

  /// Fixed warning gradient (kept for alerts)
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  /// Fixed info gradient (kept for alerts)
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

/// Password assigned to every student created via CSV import.
/// Imported students all share this default; they can change it later
/// (or the admin can) through the edit flow.
const String kDefaultStudentPassword = 'northlink';

/// Marker stored in `password_hash` / `salt` for accounts whose real
/// credential lives in Firebase Authentication. Nothing in the app reads
/// these values anymore; they only satisfy the data model.
const String kManagedByFirebaseAuth = 'firebase-auth';

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
