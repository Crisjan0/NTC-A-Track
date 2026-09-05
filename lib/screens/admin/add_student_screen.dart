import 'package:flutter/material.dart';

import '../../services/student_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/student_form.dart';

/// Admin "Add Student" form.
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<StudentFormState>();
  bool _saving = false;

  Future<void> _save() async {
    final data = _formKey.currentState?.validate();
    if (data == null) return;

    setState(() => _saving = true);
    try {
      await StudentService.instance.addStudent(
        studentId: data.studentId,
        lastName: data.lastName,
        firstName: data.firstName,
        course: data.course,
        yearLevel: data.yearLevel,
        password: data.password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added · QR code generated'),
        ),
      );
      Navigator.of(context).pop(true);
    } on StudentException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Add Student',
            subtitle: 'A unique QR code is created automatically',
            icon: Icons.person_add_alt_1_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassPanel(
                    radius: kCardRadius,
                    blur: 24,
                    strong: true,
                    padding: const EdgeInsets.all(18),
                    child: StudentForm(
                      key: _formKey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Add Student',
                    icon: Icons.person_add_alt_1_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
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