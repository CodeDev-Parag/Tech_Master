import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

import '../../core/constants/app_constants.dart';

class TaskRepository {
  late Box<Task> _taskBox;

  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>(AppConstants.tasksBox);
  }

  List<Task> getAllTasks() {
    return _taskBox.values.toList();
  }

  List<Task> getTasksByStatus(TaskStatus status) {
    return _taskBox.values.where((task) => task.status == status).toList();
  }

  List<Task> getTasksByCategory(String categoryId) {
    return _taskBox.values
        .where((task) => task.categoryId == categoryId)
        .toList();
  }

  List<Task> getTasksByPriority(Priority priority) {
    return _taskBox.values.where((task) => task.priority == priority).toList();
  }

  List<Task> getTodaysTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!
              .isAfter(today.subtract(const Duration(seconds: 1))) &&
          task.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return _taskBox.values
        .where((task) =>
            task.dueDate != null &&
            task.dueDate!.isBefore(now) &&
            task.status != TaskStatus.completed)
        .toList();
  }

  List<Task> getUpcomingTasks({int days = 7}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    return _taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(now) && task.dueDate!.isBefore(futureDate);
    }).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  Task? getTaskById(String id) {
    try {
      return _taskBox.values.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    task.updatedAt = DateTime.now();
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  Future<void> toggleTaskStatus(String id) async {
    final task = getTaskById(id);
    if (task != null) {
      if (task.status == TaskStatus.completed) {
        task.status = TaskStatus.pending;
      } else {
        task.status = TaskStatus.completed;
      }
      await updateTask(task);
    }
  }

  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    final task = getTaskById(taskId);
    if (task != null) {
      final subTaskIndex = task.checklist.indexWhere((s) => s.id == subTaskId);
      if (subTaskIndex != -1) {
        task.checklist[subTaskIndex].isCompleted =
            !task.checklist[subTaskIndex].isCompleted;

        // Auto-complete task if all subtasks are done
        if (task.checklist.every((s) => s.isCompleted)) {
          task.status = TaskStatus.completed;
        } else if (task.status == TaskStatus.completed) {
          task.status = TaskStatus.inProgress;
        }

        await updateTask(task);
      }
    }
  }

  // Statistics
  Map<String, dynamic> getStatistics() {
    final tasks = getAllTasks();
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdue = getOverdueTasks().length;

    return {
      'total': tasks.length,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'overdue': overdue,
      'completionRate': tasks.isEmpty ? 0.0 : (completed / tasks.length) * 100,
    };
  }

  // Get tasks completed in last N days for productivity chart
  List<Map<String, dynamic>> getCompletionHistory({int days = 7}) {
    final now = DateTime.now();
    final history = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(const Duration(days: 1));

      final completedOnDay = _taskBox.values
          .where((task) =>
              task.status == TaskStatus.completed &&
              task.updatedAt
                  .isAfter(date.subtract(const Duration(seconds: 1))) &&
              task.updatedAt.isBefore(nextDate))
          .length;

      history.add({
        'date': date,
        'completed': completedOnDay,
      });
    }

    return history;
  }
}
