import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/subject_attendance.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../college/timetable_screen.dart';

// Provider to fetch subjects (stream-like or future)
// Ideally we'd use a StreamProvider watching Hive box events, but for now simple refresh
final attendanceProvider =
    FutureProvider.autoDispose<List<SubjectAttendance>>((ref) async {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getAllSubjects();
});

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  // To trigger re-builds manually since we aren't using a StreamProvider for the box yet
  void _refresh() {
    ref.invalidate(attendanceProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectsAsync = ref.watch(attendanceProvider);
    final repo = ref.watch(attendanceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TimetableScreen()),
            ),
            icon: const Icon(Iconsax.calendar_1),
            tooltip: 'Timetable',
          ),
          IconButton(
            onPressed: () => _showAddSubjectDialog(context, repo),
            icon: const Icon(Iconsax.add_square),
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.chart_square, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects tracked yet',
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => _showAddSubjectDialog(context, repo),
                    child: const Text('Add Subject'),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return _AttendanceCard(
                subject: subject,
                repo: repo,
                onUpdate: _refresh,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, AttendanceRepository repo) {
    final nameController = TextEditingController();
    final targetController = TextEditingController(text: '75');
    final attendedController = TextEditingController(text: '0');
    final totalController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  prefixIcon: Icon(Iconsax.book),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target % (e.g., 75)',
                  prefixIcon: Icon(Iconsax.verify),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: attendedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Attended',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: totalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await repo.addSubject(
                  nameController.text,
                  target: double.tryParse(targetController.text) ?? 75.0,
                  attended: int.tryParse(attendedController.text) ?? 0,
                  total: int.tryParse(totalController.text) ?? 0,
                );
                _refresh();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final SubjectAttendance subject;
  final AttendanceRepository repo;
  final VoidCallback onUpdate;

  const _AttendanceCard({
    required this.subject,
    required this.repo,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = subject.currentPercentage;
    final isSafe = subject.isSafe;

    // Status Logic
    String statusText;
    Color statusColor;

    if (isSafe) {
      final bunkable = subject.classesCanBunk;
      if (bunkable > 0) {
        statusText = 'On Track! You can bunk next $bunkable classes.';
        statusColor = Colors.green;
      } else {
        statusText = 'On Track! Don\'t miss next class.';
        statusColor = Colors.green;
      }
    } else {
      final needed = subject.classesMustAttend;
      statusText = 'Danger! Attend next $needed classes to recover.';
      statusColor = Colors.red;
    }

    return Dismissible(
      key: Key(subject.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        repo.deleteSubject(subject.id);
        onUpdate();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.subjectName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSafe
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSafe ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: theme.disabledColor.withValues(alpha: 0.1),
                  color: isSafe ? Colors.green : Colors.red,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attended: ${subject.attendedClasses} / ${subject.totalClasses}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  Row(
                    children: [
                      if (subject.totalClasses > 0)
                        IconButton(
                          onPressed: () async {
                            // Ask user if they want to undo Present or Absent
                            // For simplicity, let's assume undoing the last action isn't tracked perfectly in history
                            // So we prompt: "Undo Present?" or "Undo Absent?"
                            // Or clearer: just generic undo mechanism in UI?
                            // Let's enable undoing 'Present' and 'Absent' separately via dialog or just assume last action?
                            // Repository has `undoLastAction(id, wasPresent)`.
                            // We don't know what the last action was easily without keeping history.
                            // So let's provide small '-' buttons next to counts?
                            // Or simply: "Undo" button asks "Undo Present/Absent"?
                            _showUndoDialog(context, subject);
                          },
                          icon: const Icon(Icons.undo, size: 20),
                          tooltip: 'Undo',
                        ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 8),
              Text(
                statusText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await repo.markPresent(subject.id);
                        onUpdate();
                      },
                      icon: const Icon(Iconsax.tick_circle),
                      label: const Text('Present'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await repo.markAbsent(subject.id);
                        onUpdate();
                      },
                      icon: const Icon(Iconsax.close_circle),
                      label: const Text('Absent'), // or Bunk
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUndoDialog(BuildContext context, SubjectAttendance subject) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Undo last entry'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await repo.undoLastAction(subject.id, true); // Undo Present
              onUpdate();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Undo "Present"'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await repo.undoLastAction(subject.id, false); // Undo Absent
              onUpdate();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Undo "Absent"'),
          ),
        ],
      ),
    );
  }
}
