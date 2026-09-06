import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/student_service.dart';
import '../../services/course_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
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
  List<String> _courses = kCourses;
  bool _coursesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await CourseService.instance.getAllCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses.map((c) => c.name).toList();
        _coursesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _coursesLoading = false);
    }
  }

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
    return GlassScaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Edit Student',
            subtitle: widget.student.fullName,
            icon: Icons.edit_rounded,
            leading: const GlassBackButton(),
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
                    child: _coursesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : StudentForm(
                            key: _formKey,
                            student: widget.student,
                            courseItems: _courses,
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