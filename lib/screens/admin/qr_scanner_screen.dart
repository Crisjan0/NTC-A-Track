import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/attendance_model.dart';
import '../../models/event_model.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../auth/login_screen.dart';
import 'event_management_screen.dart';

/// Dedicated admin QR scanner: opens the camera, decodes a student QR,
/// and records attendance (or reports duplicate / invalid codes).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // No `formats` restriction on purpose: on some devices restricting to
  // QR codes stops detection entirely.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handling = false;
  bool _torchOn = false;
  AttendanceEvent? _activeEvent;

  // Time In/Out event state: which AM/PM session + in/out check to record.
  String _session = 'AM';
  bool _isIn = true;

  String get _checkType => '${_session}_${_isIn ? 'IN' : 'OUT'}';

  @override
  void initState() {
    super.initState();
    _loadActiveEvent();
  }

  Future<void> _loadActiveEvent() async {
    final event = await AttendanceService.instance.activeEvent();
    if (!mounted) return;
    setState(() => _activeEvent = event);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _handling = true;
    await _controller.stop();
    try {
      final result = await AttendanceService.instance.recordFromScan(
        raw,
        checkType: _checkType,
      );
      if (!mounted) return;
      await _showResultDialog(result);
    } finally {
      // Always resume the camera and clear the guard, even if recording
      // failed, so the scanner can never get stuck after one scan.
      if (mounted) {
        _handling = false;
        await _controller.start();
      }
    }
  }

  Future<void> _showResultDialog(AttendanceResult result) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ScanResultDialog(
        result: result,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  /// Fallback when the camera cannot read the QR: type the student ID
  /// instead. Goes through the exact same recording flow as a scan.
  Future<void> _manualEntry() async {
    if (_handling) return;
    _handling = true;
    await _controller.stop();
    if (!mounted) return;
    try {
      final id = await _promptStudentId(context);
      if (id == null || id.trim().isEmpty) return;
      final result = await AttendanceService.instance.recordFromScan(
        id,
        checkType: _checkType,
      );
      if (!mounted) return;
      await _showResultDialog(result);
    } finally {
      if (mounted) {
        _handling = false;
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defense in depth: students can never open the scanner.
    final session = SessionService.instance.current;
    if (session == null || !session.isAdmin) {
      return const LoginScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // NOTE: no `scanWindow` on purpose — on many devices the
            // restricted region does not line up with the preview, so codes
            // get ignored. Detection runs across the whole camera view and
            // the overlay frame below is purely a visual guide, drawn from
            // the widget's own constraints so it is always centered.
            errorBuilder: (context, error) => _CameraErrorView(
              error: error,
              onRetry: () async {
                setState(() {});
                await _controller.start();
              },
            ),
            overlayBuilder: (context, constraints) {
              final size = constraints.biggest;
              final scanSize = size.width * 0.68;
              final scanWindow = Rect.fromCenter(
                center: Offset(size.width / 2, size.height * 0.45),
                width: scanSize,
                height: scanSize,
              );
              return _ScanOverlay(scanWindow: scanWindow);
            },
          ),
          // Top bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Scan Student QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _manualEntry,
                      tooltip: 'Enter Student ID manually',
                      icon: const Icon(
                        Icons.keyboard_alt_outlined,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Session + check type toggles (only for Time In/Out events).
          if (_activeEvent?.usesTimeInOut ?? false)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 66,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _ToggleRow(
                    options: const ['AM', 'PM'],
                    selected: _session,
                    onSelect: (value) => setState(() => _session = value),
                  ),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    options: const ['Time In', 'Time Out'],
                    selected: _isIn ? 'Time In' : 'Time Out',
                    onSelect: (value) =>
                        setState(() => _isIn = value == 'Time In'),
                  ),
                ],
              ),
            ),
          // Active event pill + hint text above the scan frame.
          Positioned(
            left: 24,
            right: 24,
            bottom: 140,
            child: Column(
              children: [
                if (_activeEvent != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Event: ${_activeEvent!.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Align the student\'s QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls: torch + switch camera.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      label: _torchOn ? 'Torch On' : 'Torch Off',
                      onTap: () async {
                        await _controller.toggleTorch();
                        if (mounted) {
                          setState(() => _torchOn = !_torchOn);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    _ControlButton(
                      icon: Icons.cameraswitch_rounded,
                      label: 'Switch',
                      onTap: () => _controller.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog asking the admin to type a student ID (fallback when the camera
/// cannot scan). Returns the trimmed ID, or null if cancelled.
Future<String?> _promptStudentId(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Enter Student ID'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'e.g. 2026-0001',
          prefixIcon: Icon(Icons.badge_rounded),
        ),
        onSubmitted: (value) => Navigator.of(ctx).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Record'),
        ),
      ],
    ),
  );
}

/// Semi-transparent mask + corner brackets around the scan window.
class _ScanOverlay extends StatelessWidget {
  final Rect scanWindow;

  const _ScanOverlay({required this.scanWindow});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanPainter(scanWindow: scanWindow),
    );
  }
}

class _ScanPainter extends CustomPainter {
  final Rect scanWindow;

  _ScanPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)),
      );
    canvas.drawPath(
      mask,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Corner brackets.
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const corner = 28.0;

    final topLeft = Path()
      ..moveTo(scanWindow.left, scanWindow.top + corner)
      ..lineTo(scanWindow.left, scanWindow.top)
      ..lineTo(scanWindow.left + corner, scanWindow.top);
    final topRight = Path()
      ..moveTo(scanWindow.right - corner, scanWindow.top)
      ..lineTo(scanWindow.right, scanWindow.top)
      ..lineTo(scanWindow.right, scanWindow.top + corner);
    final bottomRight = Path()
      ..moveTo(scanWindow.right, scanWindow.bottom - corner)
      ..lineTo(scanWindow.right, scanWindow.bottom)
      ..lineTo(scanWindow.right - corner, scanWindow.bottom);
    final bottomLeft = Path()
      ..moveTo(scanWindow.left + corner, scanWindow.bottom)
      ..lineTo(scanWindow.left, scanWindow.bottom)
      ..lineTo(scanWindow.left, scanWindow.bottom - corner);

    for (final path in [topLeft, topRight, bottomRight, bottomLeft]) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill toggle used for the AM/PM and Time In/Time Out selectors.
class _ToggleRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ToggleRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: option == selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelect(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: option == selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onRetry;

  const _CameraErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: const Color(0xFF1C1B22),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            denied ? Icons.no_photography_rounded : Icons.camera_alt_outlined,
            size: 56,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 20),
          Text(
            denied ? 'Camera permission denied' : 'Camera unavailable',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            denied
                ? 'Enable camera access in your device settings to scan '
                    'student QR codes.'
                : 'The camera could not be started. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 48),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// Result dialog after a scan: success / already recorded / invalid.
class _ScanResultDialog extends StatelessWidget {
  final AttendanceResult result;
  final VoidCallback onClose;

  const _ScanResultDialog({
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final student = result.student;
    final record = result.attendance;

    switch (result.type) {
      case AttendanceResultType.success:
        return _OutcomeDialog(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          iconBg: AppColors.successLight,
          title: 'Attendance Recorded Successfully',
          onClose: onClose,
          child: _StudentSummary(
            student: student!,
            record: record,
            eventName: result.eventName,
          ),
        );
      case AttendanceResultType.alreadyRecorded:
        return _OutcomeDialog(
          icon: Icons.history_rounded,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningLight,
          title: 'Attendance Already Recorded',
          onClose: onClose,
          child: student == null || record == null
              ? null
              : Column(
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your attendance for today has already been recorded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Time: ${Formatters.time(record.time)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
        );
      case AttendanceResultType.studentNotFound:
        return _OutcomeDialog(
          icon: Icons.error_rounded,
          iconColor: AppColors.danger,
          iconBg: AppColors.dangerLight,
          title: 'Invalid QR Code',
          onClose: onClose,
          child: const Column(
            children: [
              Text(
                'Student Not Found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'No attendance was recorded. Please scan a valid '
                'student QR code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _OutcomeDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget? child;
  final VoidCallback onClose;

  const _OutcomeDialog({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onClose,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // The scanner is a full-screen camera, so the result sheet keeps a
    // light frosted surface in both appearances for contrast.
    return Dialog(
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue Scanning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentSummary extends StatelessWidget {
  final Student student;
  final Attendance? record;
  final String? eventName;

  const _StudentSummary({
    required this.student,
    required this.record,
    this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    final event = eventName;
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: 14,
      blur: 18,
      showSheen: false,
      fill: p.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _SummaryRow(label: 'Student ID', value: student.studentId),
          _SummaryRow(label: 'Name', value: student.fullName),
          _SummaryRow(label: 'Course', value: student.course),
          _SummaryRow(label: 'Year Level', value: student.yearLevel),
          if (event != null && event.isNotEmpty)
            _SummaryRow(label: 'Event', value: event),
          if (record != null) ...[
            _SummaryRow(
              label: 'Date',
              value: Formatters.fullDate(record!.date),
            ),
            _SummaryRow(
              label: 'Time',
              value: Formatters.time(record!.time),
            ),
            if (record!.checkType != CheckType.present)
              _SummaryRow(
                label: 'Check',
                value: CheckType.label(record!.checkType),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _PresentBadge(
                label: record!.checkType == CheckType.present
                    ? null
                    : CheckType.label(record!.checkType),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentBadge extends StatelessWidget {
  /// Custom label (e.g. "AM Time In"); defaults to "STATUS: PRESENT".
  final String? label;

  const _PresentBadge({this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: AppColors.success,
          ),
          const SizedBox(width: 5),
          Text(
            label?.toUpperCase() ?? 'STATUS: PRESENT',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Landing page for the Scan tab: instructions + button that opens the
/// full-screen camera scanner.
class QrScanLandingPage extends StatefulWidget {
  const QrScanLandingPage({super.key});

  @override
  State<QrScanLandingPage> createState() => _QrScanLandingPageState();
}

class _QrScanLandingPageState extends State<QrScanLandingPage> {
  AttendanceEvent? _activeEvent;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final event = await AttendanceService.instance.activeEvent();
    if (!mounted) return;
    setState(() => _activeEvent = event);
  }

  Future<void> _openEventManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EventManagementScreen()),
    );
    await _loadEvent();
  }

  /// Fallback when the camera cannot read the QR: type the student ID.
  Future<void> _manualEntry() async {
    final id = await _promptStudentId(context);
    if (id == null || id.trim().isEmpty) return;
    final result = await AttendanceService.instance.recordFromScan(id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ScanResultDialog(
        result: result,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Scan QR Code',
            subtitle: _activeEvent == null
                ? 'Record attendance in one scan'
                : 'Recording to: ${_activeEvent!.name}',
            icon: Icons.qr_code_scanner_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ActiveEventCard(
                    event: _activeEvent,
                    onManage: _openEventManagement,
                  ),
                  const SizedBox(height: 16),
                  GlassPanel(
                    radius: kCardRadius,
                    blur: 26,
                    strong: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Ready to scan?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _activeEvent?.usesTimeInOut ?? false
                              ? 'Point the camera at a student\'s QR code to '
                                  'record their Time In or Time Out. Pick the '
                                  'session (AM/PM) and check type before '
                                  'scanning.'
                              : 'Point the camera at a student\'s QR code to '
                                  'record their attendance for today. Each '
                                  'student can only be marked present once '
                                  'per day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: p.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          label: 'Start Scanning',
                          icon: Icons.camera_alt_rounded,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const QrScannerScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _manualEntry,
                          icon: const Icon(Icons.keyboard_alt_outlined),
                          label: const Text('Enter ID Manually'),
                          style: TextButton.styleFrom(
                            foregroundColor: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _StepRow(
                    number: '1',
                    text: 'Ask the student to open their QR code',
                    icon: Icons.qr_code_2_rounded,
                  ),
                  const SizedBox(height: 10),
                  const _StepRow(
                    number: '2',
                    text: 'Scan the code with the camera',
                    icon: Icons.center_focus_strong_rounded,
                  ),
                  const SizedBox(height: 10),
                  const _StepRow(
                    number: '3',
                    text: 'Confirm the student details shown',
                    icon: Icons.verified_user_rounded,
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

/// Compact card showing the event attendance is currently recorded to.
class _ActiveEventCard extends StatelessWidget {
  final AttendanceEvent? event;
  final VoidCallback onManage;

  const _ActiveEventCard({required this.event, required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE EVENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event?.name ?? 'General Attendance',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Change',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  final IconData icon;

  const _StepRow({
    required this.number,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 16,
      blur: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: p.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}