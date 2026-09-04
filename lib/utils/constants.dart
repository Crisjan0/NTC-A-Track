import 'package:flutter/material.dart';

/// App-wide constants: colors, spacing, labels.
class AppColors {
  AppColors._();

  // Brand palette — deep indigo with violet accents.
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

/// Brand gradient used on headers, buttons and accent elements.
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
const double kFieldRadius = 14;
const double kButtonRadius = 14;