import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final bool showCategory;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.showCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == TaskStatus.completed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: task.isOverdue && !isDone
              ? Border.all(
                  color: AppTheme.priorityUrgent.withValues(alpha: 0.5),
                  width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: isDone
                          ? _getPriorityColor(task.priority)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDone
                            ? _getPriorityColor(task.priority)
                            : _getPriorityColor(task.priority)
                                .withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.5)
                              : null,
                        ),
                      ),

                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Meta info row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Priority
                          _metaChip(
                            _getPriorityLabel(task.priority),
                            _getPriorityColor(task.priority),
                            theme,
                          ),

                          // Due date
                          if (task.dueDate != null)
                            _metaChip(
                              DateFormat('MMM d').format(task.dueDate!),
                              task.isOverdue
                                  ? AppTheme.priorityUrgent
                                  : theme.colorScheme.primary,
                              theme,
                              icon: Iconsax.calendar_1,
                            ),

                          // Recurrence
                          if (task.recurrence != RecurrenceType.none)
                            _metaChip(
                              _getRecurrenceLabel(task.recurrence),
                              theme.colorScheme.secondary,
                              theme,
                              icon: Iconsax.repeat,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                ),
              ],
            ),

            // Subtasks progress
            if (task.checklist.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: task.checklistProgress,
                        minHeight: 6,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.checklistProgress == 1.0
                              ? AppTheme.statusCompleted
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${task.checklist.where((s) => s.isCompleted).length}/${task.checklist.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String label, Color color, ThemeData theme,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
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

  String _getPriorityLabel(Priority priority) {
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

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return '';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }
}
