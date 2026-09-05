import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/qr_display_card.dart';

/// Shows the logged-in student their own QR code.
class MyQrCodeScreen extends StatefulWidget {
  const MyQrCodeScreen({super.key});

  @override
  State<MyQrCodeScreen> createState() => _MyQrCodeScreenState();
}

class _MyQrCodeScreenState extends State<MyQrCodeScreen> {
  Student? _student;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final student = await AuthService.instance.currentStudent();
    if (!mounted) return;
    setState(() => _student = student);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final scheme = Theme.of(context).colorScheme;
    final student = _student;
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            title: 'My QR Code',
            subtitle: 'Show this to the admin when scanning',
            icon: Icons.qr_code_2_rounded,
          ),
          Expanded(
            child: student == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        QrDisplayCard(student: student),
                        const SizedBox(height: 20),
                        GlassPanel(
                          radius: 16,
                          blur: 18,
                          borderWidth: 0.8,
                          showSheen: false,
                          color: scheme.primary,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: p.isDark ? scheme.primary : scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Present this QR code to the admin '
                                  'to record your attendance. It contains '
                                  'your Student ID.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                            ],
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
