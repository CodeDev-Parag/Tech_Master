import '../models/task.dart';
import 'package:intl/intl.dart';

class TaskPatternInsight {
  final String title;
  final String description;
  final double confidence;

  TaskPatternInsight({
    required this.title,
    required this.description,
    required this.confidence,
  });
}

class PatternAnalysisService {
  /// Analyzes task patterns to provide productivity insights locally
  List<TaskPatternInsight> analyzePatterns(List<Task> tasks) {
    if (tasks.isEmpty) return [];

    final insights = <TaskPatternInsight>[];

    // 1. Analyze Peak Productivity Times
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).toList();
    if (completedTasks.length > 3) {
      final hourCounts = <int, int>{};
      for (var task in completedTasks) {
        final hour = task.updatedAt.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      final peakHour =
          hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final timeStr = DateFormat('h a').format(DateTime(2024, 1, 1, peakHour));

      insights.add(TaskPatternInsight(
        title: 'Peak Productivity',
        description:
            'You tend to finish most tasks around $timeStr. Consider scheduling your deep work then.',
        confidence: 0.85,
      ));
    }

    // 2. Category Affinity
    final categoryCounts = <String, int>{};
    for (var task in tasks) {
      if (task.categoryId != null) {
        categoryCounts[task.categoryId!] =
            (categoryCounts[task.categoryId!] ?? 0) + 1;
      }
    }

    if (categoryCounts.isNotEmpty) {
      final topCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      insights.add(TaskPatternInsight(
        title: 'Focus Area',
        description:
            'You are most active in this category. Great job keeping your focus consistent!',
        confidence: 0.7,
      ));
    }

    // 3. Completion Rate Analysis
    if (tasks.length > 5) {
      final rate = completedTasks.length / tasks.length;
      if (rate > 0.8) {
        insights.add(TaskPatternInsight(
          title: 'High Achiever',
          description:
              'Your completion rate is ${(rate * 100).toStringAsFixed(0)}%! You are crushing your goals.',
          confidence: 0.9,
        ));
      } else if (rate < 0.4) {
        insights.add(TaskPatternInsight(
          title: 'Workload Balance',
          description:
              'You have many pending tasks. Try breaking them into smaller subtasks to gain momentum.',
          confidence: 0.75,
        ));
      }
    }

    return insights;
  }
}
