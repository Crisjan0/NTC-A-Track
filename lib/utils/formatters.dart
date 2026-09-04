import 'package:intl/intl.dart';

/// Date & time formatting helpers using intl.
class Formatters {
  Formatters._();

  static final DateFormat _date = DateFormat('MMMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _dbDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _time = DateFormat('h:mm a');

  /// "September 4, 2026"
  static String fullDate(DateTime d) => _date.format(d);

  /// "Sep 4, 2026"
  static String shortDate(DateTime d) => _shortDate.format(d);

  /// "2026-09-04" — key used by the database.
  static String dbDate(DateTime d) => _dbDate.format(d);

  /// "8:05 AM"
  static String time(DateTime d) => _time.format(d);

  /// "2026-09-04 · 8:05 AM"
  static String dateTime(DateTime d) => '${_shortDate.format(d)} · ${_time.format(d)}';

  /// "92%"
  static String percent(double value) => '${value.round()}%';
}