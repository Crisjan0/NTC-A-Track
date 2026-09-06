import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/student_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/student_csv.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/gradient_header.dart';

/// Admin "Import Students" flow: pick a CSV file, preview the parsed rows,
/// then insert them all with the shared default password.
class ImportStudentsScreen extends StatefulWidget {
  const ImportStudentsScreen({super.key});

  @override
  State<ImportStudentsScreen> createState() => _ImportStudentsScreenState();
}

class _ImportStudentsScreenState extends State<ImportStudentsScreen> {
  String? _fileName;
  List<StudentImportRow> _rows = [];
  bool _picking = false;
  bool _downloading = false;
  bool _importing = false;

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage('Could not read the selected file.');
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      final rows = parseStudentCsv(content);
      if (!mounted) return;

      if (rows.isEmpty) {
        _showMessage('No student rows found in this file.');
        return;
      }

      setState(() {
        _fileName = file.name;
        _rows = rows;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not open the file. Please try again.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _downloading = true);
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save CSV template',
        fileName: kStudentCsvTemplateFileName,
        bytes: utf8.encode(buildStudentCsvTemplate()),
        type: FileType.custom,
        allowedExtensions: ['csv'],
        mimeType: 'text/csv',
      );
      if (uri == null) return; // user cancelled the save dialog
      if (!mounted) return;
      _showMessage('Template saved — fill it in, then choose the file above');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not save the template. Please try again.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await StudentService.instance.importStudents(_rows);
      if (!mounted) return;

      if (result.skippedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.imported} '
              '${result.imported == 1 ? 'student' : 'students'} imported · '
              'default password: $kDefaultStudentPassword',
            ),
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }

      await _showImportSummary(result);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _showImportSummary(StudentImportResult result) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Complete'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.imported} '
                '${result.imported == 1 ? 'student was' : 'students were'} '
                'imported with the default password "$kDefaultStudentPassword".',
              ),
              if (result.skippedCount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${result.skippedCount} '
                  '${result.skippedCount == 1 ? 'row was' : 'rows were'} skipped:',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < result.skipped.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${result.skipped[i].fullName} '
                              '(${result.skipped[i].studentId}) — '
                              '${result.skippedReasons[i]}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Import Students',
            subtitle: 'Add many students at once from a CSV file',
            icon: Icons.upload_file_rounded,
            leading: const GlassBackButton(),
          ),
          Expanded(
            child: _rows.isEmpty ? _buildPickState() : _buildPreviewState(),
          ),
        ],
      ),
    );
  }

  Widget _buildPickState() {
    final p = AppTheme.paletteOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassPanel(
            radius: kCardRadius,
            blur: 24,
            strong: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 20, color: p.textSecondary),
                    const SizedBox(width: 8),
                    const Text(
                      'CSV file format',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'One student per row with these columns:',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Student ID, First Name, Last Name, Course, Year Level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.glassFillSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.borderStroke),
                  ),
                  child: const Text(
                    '2026-0100,Juan,Dela Cruz,BS Information Technology,1st Year\n'
                    '2026-0101,Maria,Santos,BS Nursing,2nd Year',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A header row is optional — matching column names are '
                  'detected automatically.',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            radius: kCardRadius,
            blur: 24,
            strong: true,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 20, color: p.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Password is NOT part of the file. Every imported '
                    'student gets the default password '
                    '"$kDefaultStudentPassword" and can be changed later '
                    'via Edit Student.',
                    style: TextStyle(fontSize: 13, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Download Template',
            icon: Icons.download_rounded,
            loading: _downloading,
            onPressed: _downloading ? null : _downloadTemplate,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Choose CSV File',
            icon: Icons.folder_open_rounded,
            loading: _picking,
            onPressed: _picking ? null : _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    final p = AppTheme.paletteOf(context);
    final count = _rows.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: GlassPanel(
            radius: kCardRadius,
            blur: 24,
            strong: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fileName ?? 'Imported file',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _importing ? null : _pickFile,
                      child: const Text('Choose another file'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count == 1 ? 'student' : 'students'} found — '
                  'review the rows below before importing.',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'All imported students will use the default password '
                  '"$kDefaultStudentPassword".',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            itemCount: _rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = _rows[index];
              return GlassPanel(
                radius: 16,
                blur: 16,
                borderWidth: 0.8,
                showSheen: false,
                fill: p.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.glassFillStrong,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.studentId.isEmpty
                                ? '(no student ID)'
                                : row.studentId,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.fullName.trim().isEmpty
                                ? '(missing name)'
                                : row.fullName,
                            style: TextStyle(
                              fontSize: 13,
                              color: p.textSecondary,
                            ),
                          ),
                          if (row.course.isNotEmpty ||
                              row.yearLevel.isNotEmpty)
                            Text(
                              [
                                if (row.course.isNotEmpty) row.course,
                                if (row.yearLevel.isNotEmpty) row.yearLevel,
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: CustomButton(
            label: count == 1 ? 'Import 1 student' : 'Import $count students',
            icon: Icons.check_circle_outline_rounded,
            loading: _importing,
            onPressed: _importing ? null : _import,
          ),
        ),
      ],
    );
  }
}