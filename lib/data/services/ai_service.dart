import 'package:flutter/material.dart';
import '../models/task.dart';
import 'local_ml_service.dart';

class ParsedTask {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final Priority? priority;
  final String? category; // Added category
  final List<String> suggestedSubtasks;

  ParsedTask({
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.category,
    this.suggestedSubtasks = const [],
  });
}

class ProductivityInsight {
  final String summary;
  final List<String> tips;
  final double productivityScore;
  final String recommendation;

  ProductivityInsight({
    required this.summary,
    required this.tips,
    required this.productivityScore,
    required this.recommendation,
  });
}

class AIService extends ChangeNotifier {
  final LocalMLService _mlService;

  AIService(this._mlService);

  // Always true now as we are running locally
  bool get isConfigured => true;

  Future<void> init() async {
    // No initialization needed for local mode
  }

  /// Trains the local AI model on the user's dataset
  void trainModel(List<Task> tasks) {
    _mlService.train(tasks);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    // No-op
  }

  String? get apiKey => null;

  /// Simulates a chat response using local logic
  Future<String> chat(String message, {String? context}) async {
    // Simulate thinking time
    await Future.delayed(const Duration(milliseconds: 600));

    final lower = message.toLowerCase();

    // Productivity and Procrastination
    if (lower.contains('procrastinat') ||
        lower.contains('lazy') ||
        lower.contains('put off')) {
      return "Procrastination is often a defense mechanism against stress. Try the '5-Second Rule': when you have an impulse to act on a goal, you must physically move within 5 seconds or your brain will kill the idea. Also check out the new 'Procrastination Combat' section in the app!";
    }

    if (lower.contains('focus') ||
        lower.contains('distraction') ||
        lower.contains('concentrate')) {
      return "To sharpen your focus, I recommend the 'Deep Work' approach: schedule 90-minute blocks of zero-distraction time. Using the Pomodoro timer (25/5) is also a great way to build focus muscles.";
    }

    if (lower.contains('pattern') || lower.contains('habit')) {
      return "I've been analyzing your recent tasks. You seem most productive in the mornings! Try scheduling your high-priority tasks before 11 AM to ride that wave of energy.";
    }

    if (lower.contains('note') || lower.contains('write')) {
      return "You can use the new Notes feature to capture ideas quickly. You can even export them as high-quality PDFs or images to share with others!";
    }

    // Task management
    if (lower.contains('how') && lower.contains('busy')) {
      return "Based on your current list, $context. You have a few high-priority tasks that need attention. Want me to help you break one down?";
    }

    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return "Hi there! I'm your Tech Master assistant. I'm here to help you crush your goals, manage your notes, and beat procrastination. What's on your mind?";
    }

    if (lower.contains('help') || lower.contains('what can you do')) {
      return "I can help you:\n1. Add tasks using natural language (e.g., 'Remind me to call Mom tomorrow at 5pm')\n2. Combat procrastination with proven techniques\n3. Organize your thoughts in the Notes section\n4. Analyze your productivity patterns";
    }

    // Default fallback - more encouraging
    return "That's an interesting point. To help me assist you better, could you tell me more? For example, are you feeling overwhelmed with your current tasks, or looking for a way to organize your ideas?";
  }

  /// Parses natural language input using Regex AND Local ML
  Future<ParsedTask> parseNaturalLanguage(String input) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 300));

    String title = input;
    DateTime now = DateTime.now();
    DateTime? dueDate;
    TimeOfDay? dueTime;
    Priority? priority;

    final lowerInput = input.toLowerCase();

    // 1. Detect Date (Regex Heuristics)
    if (lowerInput.contains('today')) {
      dueDate = now;
      title = _removeKeyword(title, 'today');
    } else if (lowerInput.contains('tomorrow')) {
      dueDate = now.add(const Duration(days: 1));
      title = _removeKeyword(title, 'tomorrow');
    } else if (lowerInput.contains('next week')) {
      dueDate = now.add(const Duration(days: 7));
      title = _removeKeyword(title, 'next week');
    }

    // 2. Detect Time (Specific Regex)
    // Matches: 5pm, 5:30pm, 5 am, 17:00
    final timeRegex =
        RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(title);

    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = int.parse(timeMatch.group(2) ?? '0');
      String period = timeMatch.group(3)!.toLowerCase();

      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      dueTime = TimeOfDay(hour: hour, minute: minute);

      // Remove the time string from title
      title = title.replaceAll(timeMatch.group(0)!, '');
    }

    // Combine Date and Time
    if (dueDate != null && dueTime != null) {
      dueDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime.hour,
        dueTime.minute,
      );
    } else if (dueDate == null && dueTime != null) {
      // If time is given but no date, assume today (or tomorrow if time passed)
      final todayTime =
          DateTime(now.year, now.month, now.day, dueTime.hour, dueTime.minute);
      if (todayTime.isBefore(now)) {
        dueDate = todayTime.add(const Duration(days: 1));
      } else {
        dueDate = todayTime;
      }
    }

    // 3. Detect Priority (Regex + ML Fallback)
    if (lowerInput.contains('urgent') || lowerInput.contains('priority high')) {
      priority = Priority.urgent;
      title = _removeKeyword(title, 'urgent');
      title = _removeKeyword(title, 'priority high');
    } else if (lowerInput.contains('high priority')) {
      priority = Priority.high;
      title = _removeKeyword(title, 'high priority');
    } else if (lowerInput.contains('medium')) {
      priority = Priority.medium;
      title = _removeKeyword(title, 'medium');
    } else if (lowerInput.contains('low')) {
      priority = Priority.low;
      title = _removeKeyword(title, 'low');
    } else {
      // ML Prediction for Priority if not specified
      priority = _mlService.predictPriority(title);
    }

    // Clean up title for ML prediction
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Remove simplistic "at" if it lingers from "at 5pm"
    title = _removeKeyword(title, ' at ');

    // 4. Predict Category (ML)
    final predictedCategory = _mlService.predictCategory(title);

    return ParsedTask(
      title: title,
      dueDate: dueDate,
      priority: priority,
      category: predictedCategory,
      suggestedSubtasks: await generateSubtasks(title),
    );
  }

  String _removeKeyword(String text, String keyword) {
    return text.replaceAll(RegExp(keyword, caseSensitive: false), '');
  }

  Future<List<String>> generateSubtasks(String taskTitle,
      {String? description}) async {
    // Local logic for simple subtasks
    final lower = taskTitle.toLowerCase();

    if (lower.contains('shopping') || lower.contains('groceries')) {
      return ['Make a list', 'Check fridge', 'Go to store', 'Checkout'];
    }
    if (lower.contains('study') || lower.contains('read')) {
      return ['Read chapter', 'Take notes', 'Review key concepts'];
    }
    if (lower.contains('clean')) {
      return [
        'Gather supplies',
        'De-clutter',
        'Wipe surfaces',
        'Vacuum/Mopping'
      ];
    }

    return [];
  }

  Future<ProductivityInsight> getProductivityInsights(List<Task> tasks) async {
    if (tasks.isEmpty) {
      return ProductivityInsight(
        summary: 'Start adding tasks to see insights!',
        tips: ['Use the + button to add a task'],
        productivityScore: 0,
        recommendation: 'Plan your day effectively.',
      );
    }

    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final total = tasks.length;
    final completionRate = total > 0 ? (completed / total) : 0.0;

    // Generate insight based on stats
    String summary;
    String recommendation;
    List<String> tips = [];

    if (completionRate > 0.8) {
      summary = 'You are on a roll! Excellent completion rate.';
      recommendation = 'Consider taking on more challenging tasks.';
      tips.add('Keep this momentum going!');
    } else if (completionRate > 0.5) {
      summary = 'Good progress, but there is room for improvement.';
      recommendation =
          'Try to finish your pending tasks before adding new ones.';
      tips.add('Focus on one task at a time.');
    } else {
      summary = 'It seems you have many pending tasks.';
      recommendation = 'Pick the easiest task and finish it today.';
      tips.add('Break big tasks into small steps.');
    }

    return ProductivityInsight(
      summary: summary,
      tips: tips,
      productivityScore: completionRate * 100,
      recommendation: recommendation,
    );
  }
}
