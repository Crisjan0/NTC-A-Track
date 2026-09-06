import 'package:flutter/material.dart';

import '../../models/student_model.dart';
import '../../services/student_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/student_card.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'import_students_screen.dart';
import 'qr_view_screen.dart';

/// Admin student management: list, search, filter, add, edit, delete.
class StudentManagementScreen extends StatefulWidget {
  /// When true (e.g. from the dashboard quick action), the add form
  /// opens immediately.
  final bool addMode;

  const StudentManagementScreen({super.key, this.addMode = false});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _service = StudentService.instance;
  final _searchController = TextEditingController();

  List<Student> _students = [];
  bool _loading = true;
  String? _course;
  String? _yearLevel;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.addMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAdd());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _service.searchAndFilter(
      search: _searchController.text,
      course: _course,
      yearLevel: _yearLevel,
    );
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddStudentScreen()),
    );
    if (added == true) _load();
  }

  Future<void> _openImport() async {
    final imported = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ImportStudentsScreen()),
    );
    if (imported == true) _load();
  }

  Future<void> _openEdit(Student student) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditStudentScreen(student: student)),
    );
    if (changed == true) _load();
  }

  Future<void> _openView(Student student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QrViewScreen(student: student)),
    );
  }

  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text(
          'This will permanently remove ${student.fullName} '
          '(${student.studentId}) and their attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _service.deleteStudent(student);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student deleted successfully')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Students',
            subtitle:
                '${_students.length} ${_students.length == 1 ? 'record' : 'records'}',
            icon: Icons.group_rounded,
            trailing: IconButton(
              onPressed: _openImport,
              tooltip: 'Import students from a CSV file',
              icon: const Icon(
                Icons.upload_file_rounded,
                color: Colors.white,
                size: 22,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Search by ID or name…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown<String>(
                        hint: 'All Courses',
                        value: _course,
                        items: kCourses,
                        onChanged: (v) {
                          _course = v;
                          _load();
                        },
                        leadingIcon: Icons.menu_book_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FilterDropdown<String>(
                        hint: 'All Years',
                        value: _yearLevel,
                        items: kYearLevels,
                        onChanged: (v) {
                          _yearLevel = v;
                          _load();
                        },
                        leadingIcon: Icons.grade_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'No students found',
                        subtitle:
                            'Try a different search or add a new student',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _students.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final s = _students[index];
                            return StudentCard(
                              student: s,
                              onView: () => _openView(s),
                              onEdit: () => _openEdit(s),
                              onDelete: () => _confirmDelete(s),
                              onViewQr: () => _openView(s),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -40),
        child: FloatingActionButton.extended(
          onPressed: _openAdd,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            'Add Student',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Compact dropdown used for filters.
class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final IconData leadingIcon;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: kFieldRadius,
      blur: 16,
      borderWidth: 0.8,
      showSheen: false,
      fill: p.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(leadingIcon, size: 18, color: p.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 13,
            color: p.textPrimary,
          ),
          dropdownColor: p.glassFillStrong,
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textSecondary),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  '$item',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}