import 'constants.dart';

/// Auto year level derived from the Student ID.
///
/// Convention: `YYYY-XXXX` where `YYYY` is the admission/entry year.
/// Example: `2024-5648` -> admitted 2024.
///
/// Academic year in PH starts in August, so:
/// - Aug 2026 – Jul 2027 = S.Y. 2026-2027
///
/// Mapping:
/// - S.Y. entryYear     = 1st Year
/// - S.Y. entryYear + 1 = 2nd Year
/// - S.Y. entryYear + 2 = 3rd Year
/// - S.Y. entryYear + 3 = 4th Year
/// - S.Y. entryYear + 4 and beyond = Graduated
///
/// Returns null when the ID has no parseable year prefix
/// (e.g. `12345`), so callers can fall back to the stored value.
class YearLevelAuto {
  YearLevelAuto._();

  /// `2026-0001` -> 2026, `12345` -> null.
  static int? parseEntryYear(String studentId) {
    final cleaned = studentId.trim();
    final match = RegExp(r'^(\d{4})\s*-\s*\d+').firstMatch(cleaned);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    if (year == null || year < 2000 || year > 2100) return null;
    return year;
  }

  /// Current school year starter. Aug 2026 = 2026, Feb 2027 = 2026.
  static int currentAcademicYear({DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.month >= 8 ? n.year : n.year - 1;
  }

  /// `2024-5648` in Sept 2026 -> `3rd Year`. Null if not derivable.
  static String? derive(String studentId, {DateTime? now}) {
    final entryYear = parseEntryYear(studentId);
    if (entryYear == null) return null;
    final level = currentAcademicYear(now: now) - entryYear + 1;
    if (level < 1) return kYearLevels.first; // future enrollee -> 1st Year
    if (level >= 1 && level <= kYearLevels.length) {
      return kYearLevels[level - 1];
    }
    return 'Graduated';
  }

  /// True when [studentId] carries a usable `YYYY-` prefix.
  static bool isAuto(String studentId) => parseEntryYear(studentId) != null;

  /// Preferred display value: derived when possible, else [storedYearLevel].
  /// No database change needed — this is computed on the fly.
  static String effective({
    required String studentId,
    required String storedYearLevel,
    DateTime? now,
  }) {
    return derive(studentId, now: now) ?? storedYearLevel;
  }
}
