import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/qr_display_card.dart';
import 'edit_student_screen.dart';

/// Shows a student's QR code + details (admin "View" / "View QR").
class QrViewScreen extends StatelessWidget {
  final Student student;

  const QrViewScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Student QR Code',
            subtitle: student.studentId,
            icon: Icons.qr_code_2_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  QrDisplayCard(student: student),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final changed = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditStudentScreen(student: student),
                              ),
                            );
                            if (changed == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student updated'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          label: 'Done',
                          icon: Icons.check_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
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