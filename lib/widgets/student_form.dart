import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/year_level.dart';

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
    // Rebuild so the auto year-level preview updates while typing the ID.
    _idController.addListener(_onIdChanged);
  }

  void _onIdChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _idController.removeListener(_onIdChanged);
    _idController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates and returns the collected data, or null if invalid.
  ///
  /// Year level is AUTO-DERIVED from the Student ID (`YYYY-XXXX`).
  /// The manual dropdown is only a fallback for non-standard IDs.
  StudentFormData? validate() {
    if (!_formKey.currentState!.validate()) return null;
    final id = _idController.text.trim();
    final autoYear = YearLevelAuto.derive(id);
    final yearLevel = autoYear ?? _yearLevel;
    if (_course == null || yearLevel == null || yearLevel.isEmpty) {
      return null;
    }
    return StudentFormData(
      studentId: id,
      lastName: _lastNameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      course: _course!,
      yearLevel: yearLevel,
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
          Builder(
            builder: (context) {
              final autoYear =
                  YearLevelAuto.derive(_idController.text.trim());
              if (autoYear != null) {
                // Automatic mode: derived from Student ID, no manual input.
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.grade_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Year Level (Auto)',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              autoYear,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AUTO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Fallback: non-standard ID (e.g. 12345) -> manual pick.
              return DropdownButtonFormField<String>(
                initialValue: _yearLevel,
                validator: (v) => Validators.picker(v, field: 'Year level'),
                decoration: const InputDecoration(
                  labelText: 'Year Level (manual — ID has no year)',
                  prefixIcon: Icon(Icons.grade_rounded),
                ),
                items: [...kYearLevels, 'Graduated']
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (v) => setState(() => _yearLevel = v),
              );
            },
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