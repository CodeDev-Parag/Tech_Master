import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/models/category.dart';
import '../../providers/providers.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? editTask;

  const AddTaskScreen({super.key, this.editTask});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _naturalInputController = TextEditingController();
  final _subTaskController = TextEditingController();
  final _uuid = const Uuid();

  Priority _priority = Priority.medium;
  TaskStatus _status = TaskStatus.pending;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  DateTime? _reminderTime;
  String? _categoryId;
  RecurrenceType _recurrence = RecurrenceType.none;
  List<SubTask> _subTasks = [];
  bool _isNaturalInput = true;
  bool _isGeneratingSubtasks = false;

  @override
  void initState() {
    super.initState();
    if (widget.editTask != null) {
      _loadEditTask();
      _isNaturalInput = false;
    }
  }

  void _loadEditTask() {
    final task = widget.editTask!;
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _priority = task.priority;
    _status = task.status;
    _dueDate = task.dueDate;
    _dueTime =
        task.dueDate != null ? TimeOfDay.fromDateTime(task.dueDate!) : null;
    _reminderTime = task.reminderTime;
    _categoryId = task.categoryId;
    _recurrence = task.recurrence;
    _subTasks = List.from(task.checklist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _naturalInputController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider);
    final aiService = ref.read(aiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTask != null ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Input Mode Switcher
            if (widget.editTask == null && aiService.isConfigured)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        'Natural',
                        Iconsax.magic_star,
                        _isNaturalInput,
                        () => setState(() => _isNaturalInput = true),
                        theme,
                      ),
                    ),
                    Expanded(
                      child: _modeButton(
                        'Manual',
                        Iconsax.edit_2,
                        !_isNaturalInput,
                        () => setState(() => _isNaturalInput = false),
                        theme,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 20),

            // Natural Language Input
            if (_isNaturalInput && aiService.isConfigured) ...[
              Text(
                'Describe your task naturally',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _naturalInputController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g., "Complete project report by tomorrow 5pm, high priority"',
                  hintStyle:
                      TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
                  suffixIcon: IconButton(
                    icon: Icon(Iconsax.magic_star,
                        color: theme.colorScheme.primary),
                    onPressed: _parseNaturalInput,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _parseNaturalInput,
                  icon: const Icon(Iconsax.magic_star),
                  label: const Text('Parse with AI'),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Title
            Text(
              'Title',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter task title',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Description
            Text(
              'Description (Optional)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add description...',
              ),
            ),

            const SizedBox(height: 24),

            // Priority
            Text(
              'Priority',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: Priority.values
                  .map(
                    (p) => Expanded(
                      child: _priorityChip(p, theme),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Category
            Text(
              'Category',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map(
                    (cat) => _categoryChip(cat, theme),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Due Date & Time
            Row(
              children: [
                Expanded(
                  child: _dateTimeSelector(
                    'Due Date',
                    _dueDate != null
                        ? DateFormat('MMM d, yyyy').format(_dueDate!)
                        : 'Select date',
                    Iconsax.calendar_1,
                    () => _selectDate(context),
                    theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateTimeSelector(
                    'Due Time',
                    _dueTime != null
                        ? _dueTime!.format(context)
                        : 'Select time',
                    Iconsax.clock,
                    () => _selectTime(context),
                    theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recurrence
            Text(
              'Repeat',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: RecurrenceType.values
                  .map(
                    (r) => ChoiceChip(
                      label: Text(_recurrenceLabel(r)),
                      selected: _recurrence == r,
                      onSelected: (selected) {
                        if (selected) setState(() => _recurrence = r);
                      },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Subtasks / Checklist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Checklist',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                if (aiService.isConfigured && _titleController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: _isGeneratingSubtasks ? null : _generateSubtasks,
                    icon: _isGeneratingSubtasks
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Icon(Iconsax.magic_star,
                            size: 18, color: theme.colorScheme.primary),
                    label: Text(
                      _isGeneratingSubtasks ? 'Generating...' : 'AI Generate',
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Add subtask field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a step...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onFieldSubmitted: (_) => _addSubTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addSubTask,
                  icon: const Icon(Iconsax.add),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subtasks list
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subTasks.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _subTasks.removeAt(oldIndex);
                  _subTasks.insert(newIndex, item);
                  // Update order
                  for (int i = 0; i < _subTasks.length; i++) {
                    _subTasks[i].order = i;
                  }
                });
              },
              itemBuilder: (context, index) {
                final subTask = _subTasks[index];
                return Dismissible(
                  key: Key(subTask.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    setState(() => _subTasks.removeAt(index));
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: AppTheme.priorityUrgent,
                    child: const Icon(Iconsax.trash, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: subTask.isCompleted,
                      onChanged: (value) {
                        setState(() {
                          _subTasks[index].isCompleted = value ?? false;
                        });
                      },
                    ),
                    title: Text(
                      subTask.title,
                      style: GoogleFonts.inter(
                        decoration: subTask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: subTask.isCompleted
                            ? theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Iconsax.menu),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, IconData icon, bool isSelected,
      VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(Priority priority, ThemeData theme) {
    final isSelected = _priority == priority;
    final color = _getPriorityColor(priority);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _priority = priority),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _priorityLabel(priority),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(Category category, ThemeData theme) {
    final isSelected = _categoryId == category.id;
    final color = Color(category.color);

    return GestureDetector(
      onTap: () =>
          setState(() => _categoryId = isSelected ? null : category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimeSelector(String label, String value, IconData icon,
      VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppTheme.priorityLow;
      case Priority.medium:
        return AppTheme.priorityMedium;
      case Priority.high:
        return AppTheme.priorityHigh;
      case Priority.urgent:
        return AppTheme.priorityUrgent;
    }
  }

  String _priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'None';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _addSubTask() {
    final text = _subTaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subTasks.add(SubTask(
        id: _uuid.v4(),
        title: text,
        order: _subTasks.length,
      ));
      _subTaskController.clear();
    });
  }

  Future<void> _parseNaturalInput() async {
    final input = _naturalInputController.text.trim();
    if (input.isEmpty) return;

    final aiService = ref.read(aiServiceProvider);

    try {
      final parsed = await aiService.parseNaturalLanguage(input);

      setState(() {
        _titleController.text = parsed.title;
        _descController.text = parsed.description ?? '';
        _dueDate = parsed.dueDate;
        if (parsed.dueDate != null) {
          _dueTime = TimeOfDay.fromDateTime(parsed.dueDate!);
        }
        if (parsed.priority != null) {
          _priority = parsed.priority!;
        }

        // Add suggested subtasks
        for (final suggestion in parsed.suggestedSubtasks) {
          _subTasks.add(SubTask(
            id: _uuid.v4(),
            title: suggestion,
            order: _subTasks.length,
          ));
        }

        _isNaturalInput = false;
      });

      if (mounted) {
        final theme = Theme.of(context);
        // Show Quick Confirm Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Iconsax.magic_star, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Task Parsed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (parsed.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    parsed.description!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (parsed.dueDate != null)
                      Chip(
                        label: Text(
                          DateFormat('MMM d, h:mm a').format(parsed.dueDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: const Icon(Iconsax.calendar_1, size: 14),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    if (parsed.priority != null)
                      Chip(
                        label: Text(
                          _priorityLabel(parsed.priority!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPriorityColor(parsed.priority!),
                          ),
                        ),
                        avatar: Icon(Iconsax.flag,
                            size: 14,
                            color: _getPriorityColor(parsed.priority!)),
                        backgroundColor: _getPriorityColor(parsed.priority!)
                            .withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Already populated, just let user edit
                },
                child: const Text('Edit Details'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveTask(); // Save immediately
                },
                child: const Text('Save Task'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing: $e')),
        );
      }
    }
  }

  Future<void> _generateSubtasks() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isGeneratingSubtasks = true);

    final aiService = ref.read(aiServiceProvider);

    try {
      final subtasks = await aiService.generateSubtasks(
        _titleController.text,
        description: _descController.text,
      );

      setState(() {
        for (final suggestion in subtasks) {
          _subTasks.add(SubTask(
            id: _uuid.v4(),
            title: suggestion,
            order: _subTasks.length,
          ));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating: $e')),
        );
      }
    } finally {
      setState(() => _isGeneratingSubtasks = false);
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    DateTime? fullDueDate;
    if (_dueDate != null) {
      fullDueDate = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime?.hour ?? 23,
        _dueTime?.minute ?? 59,
      );
    }

    final task = Task(
      id: widget.editTask?.id ?? _uuid.v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      dueDate: fullDueDate,
      reminderTime: _reminderTime,
      priority: _priority,
      status: _status,
      categoryId: _categoryId,
      tags: [],
      checklist: _subTasks,
      recurrence: _recurrence,
      createdAt: widget.editTask?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.editTask != null) {
      ref.read(tasksProvider.notifier).updateTask(task);
    } else {
      ref.read(tasksProvider.notifier).addTask(task);
    }

    Navigator.pop(context);
  }
}
