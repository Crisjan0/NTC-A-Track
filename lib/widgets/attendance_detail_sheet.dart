import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

/// Bottom sheet showing the full details of one attendance record.
///
/// For Time In/Out events it also shows the complete AM/PM picture for
/// that student on that day: AM Time In, AM Time Out, PM Time In and
/// PM Time Out (missing slots show as not yet recorded).
///
/// Open with [AttendanceDetailSheet.show].
class AttendanceDetailSheet extends StatefulWidget {
  final Attendance record;

  const AttendanceDetailSheet({super.key, required this.record});

  static Future<void> show(BuildContext context, Attendance record) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceDetailSheet(record: record),
    );
  }

  @override
  State<AttendanceDetailSheet> createState() => _AttendanceDetailSheetState();
}

class _AttendanceDetailSheetState extends State<AttendanceDetailSheet> {
  Future<Map<String, Attendance>>? _checksFuture;

  static const _slotOrder = [
    CheckType.amIn,
    CheckType.amOut,
    CheckType.pmIn,
    CheckType.pmOut,
  ];

  bool get _isTimeInOut =>
      widget.record.checkType != CheckType.present &&
      widget.record.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isTimeInOut) {
      _checksFuture = AttendanceService.instance.dayChecks(
        widget.record.studentId,
        Formatters.dbDate(widget.record.date),
        widget.record.eventId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final record = widget.record;
    final name = record.studentName ?? 'Student ${record.studentId}';
    final courseLine = [record.course, record.yearLevel]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: p.glassFillStrong,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.borderStroke),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record.studentId,
                          style: TextStyle(
                            fontSize: 13,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(status: record.status),
                ],
              ),
              const SizedBox(height: 16),
              _Row(
                icon: Icons.calendar_month_rounded,
                label: 'Date',
                value: Formatters.fullDate(record.date),
              ),
              if (courseLine.isNotEmpty)
                _Row(
                  icon: Icons.menu_book_rounded,
                  label: 'Course',
                  value: courseLine,
                ),
              if (record.eventName != null)
                _Row(
                  icon: Icons.emoji_events_rounded,
                  label: 'Event',
                  value: record.eventName!,
                ),
              if (_isTimeInOut) ...[
                const SizedBox(height: 8),
                Text(
                  'AM / PM RECORDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<Map<String, Attendance>>(
                  future: _checksFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Could not load time records.',
                          style: TextStyle(
                            fontSize: 13,
                            color: p.textSecondary,
                          ),
                        ),
                      );
                    }
                    final checks = snap.data ?? {};
                    return Column(
                      children: _slotOrder
                          .map((slot) =>
                              _SlotRow(slot: slot, record: checks[slot]))
                          .toList(),
                    );
                  },
                ),
              ] else ...[
                _Row(
                  icon: Icons.schedule_rounded,
                  label: 'Time',
                  value: Formatters.time(record.time),
                ),
                _Row(
                  icon: Icons.fact_check_rounded,
                  label: 'Check',
                  value: CheckType.label(record.checkType),
                ),
              ],
              _Row(
                icon: Icons.access_time_rounded,
                label: 'Recorded',
                value: Formatters.dateTime(record.createdAt),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters =
        parts.where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }
}

/// One AM/PM slot: the recorded time, or a "not yet" placeholder.
class _SlotRow extends StatelessWidget {
  final String slot;
  final Attendance? record;

  const _SlotRow({required this.slot, required this.record});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final isIn = slot.endsWith('_IN');
    final recorded = record != null;

    final base = recorded ? (isIn ? AppColors.info : AppColors.warning) : p.textSecondary;
    final icon = isIn ? Icons.login_rounded : Icons.logout_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: recorded
            ? base.withValues(alpha: 0.10)
            : p.textSecondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recorded
              ? base.withValues(alpha: 0.25)
              : p.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: base),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              CheckType.label(slot),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
          Text(
            recorded ? Formatters.time(record!.time) : 'Not yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: recorded ? p.textPrimary : p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: p.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
