import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/student_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/student_form.dart';

/// Admin "Edit Student" form.
class EditStudentScreen extends StatefulWidget {
  final Student student;

  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<StudentFormState>();
  bool _saving = false;

  Future<void> _save() async {
    final data = _formKey.currentState?.validate();
    if (data == null) return;

    setState(() => _saving = true);
    try {
      // Reject an ID change that collides with another student.
      if (data.studentId != widget.student.studentId) {
        final exists = await StudentService.instance
            .getByStudentId(data.studentId);
        if (exists != null) {
          throw StudentException(
            'Student ID "${data.studentId}" is already in use.',
          );
        }
      }

      final updated = Student(
        id: widget.student.id,
        studentId: data.studentId,
        lastName: data.lastName,
        firstName: data.firstName,
        course: data.course,
        yearLevel: data.yearLevel,
        passwordHash: widget.student.passwordHash,
        salt: widget.student.salt,
        createdAt: widget.student.createdAt,
      );
      await StudentService.instance.updateStudent(
        updated,
        newPassword: data.password.isEmpty ? null : data.password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student updated successfully')),
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
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Edit Student',
            subtitle: widget.student.fullName,
            icon: Icons.edit_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(kCardRadius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: StudentForm(
                      key: _formKey,
                      student: widget.student,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Save Changes',
                    icon: Icons.save_rounded,
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