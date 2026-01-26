import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/providers.dart';
import '../../../data/models/task.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  static const int _focusDuration = 25 * 60; // 25 minutes
  static const int _breakDuration = 5 * 60; // 5 minutes

  int _remainingSeconds = _focusDuration;
  bool _isFocusMode = true;
  bool _isRunning = false;
  Timer? _timer;
  String? _selectedTaskId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _completeSession();
        }
      });
    }
  }

  void _completeSession() {
    _timer?.cancel();
    setState(() => _isRunning = false);

    // Play sound or vibrate (omitted for now)

    if (_isFocusMode) {
      // Focus session done!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Focus Session Completed! Take a break.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Auto-switch to break
      setState(() {
        _isFocusMode = false;
        _remainingSeconds = _breakDuration;
      });
    } else {
      // Break done!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break is over! Back to work.')),
      );
      setState(() {
        _isFocusMode = true;
        _remainingSeconds = _focusDuration;
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isFocusMode ? _focusDuration : _breakDuration;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksProvider);
    final pendingTasks =
        tasks.where((t) => t.status != TaskStatus.completed).toList();
    final totalDuration = _isFocusMode ? _focusDuration : _breakDuration;
    final progress = 1.0 - (_remainingSeconds / totalDuration);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Focus Mode',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Show history or settings later
            },
            icon: const Icon(Iconsax.setting_2),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Focus',
                      isSelected: _isFocusMode,
                      onTap: () {
                        if (!_isRunning) {
                          setState(() {
                            _isFocusMode = true;
                            _remainingSeconds = _focusDuration;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _ModeButton(
                      label: 'Break',
                      isSelected: !_isFocusMode,
                      onTap: () {
                        if (!_isRunning) {
                          setState(() {
                            _isFocusMode = false;
                            _remainingSeconds = _breakDuration;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isFocusMode ? theme.colorScheme.primary : Colors.green,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRunning
                          ? (_isFocusMode ? 'Focusing...' : 'Resting...')
                          : 'Ready',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Iconsax.refresh, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.cardColor,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 24),
                FloatingActionButton.large(
                  onPressed: _toggleTimer,
                  backgroundColor:
                      _isFocusMode ? theme.colorScheme.primary : Colors.green,
                  child:
                      Icon(_isRunning ? Iconsax.pause : Iconsax.play, size: 40),
                ),
                const SizedBox(width: 24),
                // Placeholder for skip button
                IconButton(
                  onPressed: _completeSession, // Debug skip
                  icon: const Icon(Iconsax.forward, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.cardColor,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Task Selector
            if (_isFocusMode) ...[
              Text(
                'Working on:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Show bottom sheet to select task
                  _showTaskSelector(context, pendingTasks);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.task,
                        color: _selectedTaskId != null
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getTaskTitle(tasks),
                          style: GoogleFonts.inter(
                            color: _selectedTaskId != null
                                ? theme.textTheme.bodyLarge?.color
                                : theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Iconsax.arrow_down_1, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTaskTitle(List<Task> tasks) {
    if (_selectedTaskId == null) return 'Select a task...';
    try {
      return tasks.firstWhere((t) => t.id == _selectedTaskId).title;
    } catch (e) {
      return 'Task not found';
    }
  }

  void _showTaskSelector(BuildContext context, List<Task> tasks) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Task',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: const Icon(Iconsax.task),
                      title: Text(task.title),
                      onTap: () {
                        setState(() => _selectedTaskId = task.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.textTheme.bodyLarge?.color
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
