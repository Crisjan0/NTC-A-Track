import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/attendance_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';

/// Student's own attendance history (read-only).
class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  bool _loading = true;
  List<Attendance> _history = [];
  Student? _student;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final student = await AuthService.instance.currentStudent();
    if (student == null) return;

    final history =
        await AttendanceService.instance.studentHistory(student.studentId);
    if (!mounted) return;
    setState(() {
      _student = student;
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'My Attendance',
            subtitle: _student?.fullName,
            icon: Icons.event_note_rounded,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'No attendance yet',
                        subtitle:
                            'Ask the admin to scan your QR code to get started',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _history.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => AttendanceCard(
                            record: _history[index],
                            showStudent: false,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}