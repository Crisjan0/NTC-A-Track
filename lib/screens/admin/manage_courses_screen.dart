import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/gradient_header.dart';

/// Admin-only screen to manage academic courses: list, add, rename, delete.
class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final CourseService _service = CourseService.instance;

  List<Course> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!isAdmin()) return;
    setState(() => _loading = true);
    final courses = await _service.getAllCourses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  bool isAdmin() {
    final session = SessionService.instance.current;
    if (session == null || !session.isAdmin) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return false;
    }
    return true;
  }

  Future<void> _addCourse() async {
    final name = await _showCourseDialog(initialName: '');
    if (name == null || name.trim().isEmpty) return;
    final exists = await _service.nameExists(name);
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That course already exists.')),
      );
      return;
    }
    await _service.addCourse(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Course added: "$name"')),
    );
    await _load();
  }

  Future<void> _editCourse(Course course) async {
    final name = await _showCourseDialog(initialName: course.name);
    if (name == null || name.trim().isEmpty) return;
    if (name.trim() == course.name) {
      // No change.
      return;
    }
    final exists = await _service.nameExists(name);
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Another course with that name exists.')),
      );
      return;
    }
    await _service.updateCourse(course, name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Course updated to "$name"')),
    );
    await _load();
  }

  Future<void> _confirmDelete(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text(
          'This will permanently remove "${course.name}". '
          'Students already assigned to this course are not affected.',
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
    await _service.deleteCourse(course.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Course deleted: "${course.name}"')),
    );
    await _load();
  }

  Future<String?> _showCourseDialog({required String initialName}) async {
    final controller = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initialName.isEmpty ? 'Add Course' : 'Edit Course'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. BS Computer Science',
            prefixIcon: Icon(Icons.school_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(initialName.isEmpty ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final canAdmin = isAdmin();
    if (!canAdmin) return const SizedBox.shrink();

    return GlassScaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Manage Courses',
            subtitle: '${_courses.length} ${_courses.length == 1 ? 'course' : 'courses'}',
            icon: Icons.school_rounded,
            leading: const GlassBackButton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addCourse,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Course'),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _courses.isEmpty
                    ? const EmptyState(
                        icon: Icons.school_rounded,
                        title: 'No courses yet',
                        subtitle: 'Add your first course to start',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _courses.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _CourseRow(
                            course: _courses[index],
                            onEdit: () => _editCourse(_courses[index]),
                            onDelete: () => _confirmDelete(_courses[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseRow({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: 16,
      blur: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Created ${_shortDate(course.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit course',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: p.textSecondary,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete course',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    // Reuse formatters if available, but keep it simple here.
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
