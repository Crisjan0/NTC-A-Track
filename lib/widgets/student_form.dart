import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// Data collected by [StudentForm].
class StudentFormData {
  final String studentId;
  final String lastName;
  final String firstName;
  final String course;
  final String yearLevel;
  final String password;

  const StudentFormData({
    required this.studentId,
    required this.lastName,
    required this.firstName,
    required this.course,
    required this.yearLevel,
    required this.password,
  });
}

/// Reusable add/edit student form body with validation.
class StudentForm extends StatefulWidget {
  final Student? student;
  final bool showPassword;
  final String passwordLabel;
  final String passwordHint;
  /// Optional list of courses for the dropdown. When null, uses [kCourses].
  final List<String>? courseItems;

  const StudentForm({
    super.key,
    this.student,
    this.showPassword = true,
    this.passwordLabel = 'Password',
    this.passwordHint = 'Minimum 6 characters',
    this.courseItems,
  });

  @override
  State<StudentForm> createState() => StudentFormState();
}

class StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _passwordController;

  String? _course;
  String? _yearLevel;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _idController = TextEditingController(text: s?.studentId ?? '');
    _lastNameController = TextEditingController(text: s?.lastName ?? '');
    _firstNameController = TextEditingController(text: s?.firstName ?? '');
    _passwordController = TextEditingController();
    _course = s?.course;
    _yearLevel = s?.yearLevel;
  }

  @override
  void dispose() {
    _idController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates and returns the collected data, or null if invalid.
  StudentFormData? validate() {
    if (!_formKey.currentState!.validate()) return null;
    return StudentFormData(
      studentId: _idController.text.trim(),
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      course: _course!,
      yearLevel: _yearLevel!,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _idController,
            validator: Validators.studentId,
            decoration: const InputDecoration(
              labelText: 'Student ID Number',
              hintText: 'e.g. 2026-0001',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.name(v, field: 'First name'),
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.name(v, field: 'Last name'),
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _course,
            validator: (v) => Validators.picker(v, field: 'Course'),
            decoration: const InputDecoration(
              labelText: 'Course',
              prefixIcon: Icon(Icons.menu_book_rounded),
            ),
            items: (widget.courseItems ?? kCourses)
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _course = v),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _yearLevel,
            validator: (v) => Validators.picker(v, field: 'Year level'),
            decoration: const InputDecoration(
              labelText: 'Year Level',
              prefixIcon: Icon(Icons.grade_rounded),
            ),
            items: kYearLevels
                .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                .toList(),
            onChanged: (v) => setState(() => _yearLevel = v),
          ),
          if (widget.showPassword) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              validator: widget.student == null
                  ? Validators.password
                  : (v) {
                      if (v == null || v.isEmpty) return null; // keep existing
                      return Validators.password(v);
                    },
              decoration: InputDecoration(
                labelText: widget.passwordLabel,
                hintText: widget.passwordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          if (widget.student != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Leave password blank to keep the current one.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.paletteOf(context).textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}