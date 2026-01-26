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

    // "Knowledge Base" for Focus Assistant
    if (lower.contains('focus') || lower.contains('distraction')) {
      return "To improve focus, try the Pomodoro technique (25min work, 5min break). I can also analyze your patterns to suggest your best work hours.";
    }
    if (lower.contains('pattern') || lower.contains('habit')) {
      return "I'm learning from your tasks. The more you use the app, the better I can predict your priorities and categories.";
    }
    if (lower.contains('hello') || lower.contains('hi')) {
      return "Hello! I'm your trainable Focus Assistant. I learn from your task history to make smart suggestions.";
    }
    if (lower.contains('help')) {
      return "You can say 'Buy milk' and I'll predict it's a Personal task. Or ask 'How is my productivity?' to see insights.";
    }

    return "I've noted that. I'm constantly analyzing your task history to provide better assistance.";
  }

  /// Parses natural language input using Regex AND Local ML
  Future<ParsedTask> parseNaturalLanguage(String input) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 300));

    String title = input;
    DateTime? dueDate;
    Priority? priority;

    final lowerInput = input.toLowerCase();

    // 1. Detect Date (Regex Heuristics)
    if (lowerInput.contains('today')) {
      dueDate = DateTime.now();
      title = _removeKeyword(title, 'today');
    } else if (lowerInput.contains('tomorrow')) {
      dueDate = DateTime.now().add(const Duration(days: 1));
      title = _removeKeyword(title, 'tomorrow');
    } else if (lowerInput.contains('next week')) {
      dueDate = DateTime.now().add(const Duration(days: 7));
      title = _removeKeyword(title, 'next week');
    }

    // 2. Detect Priority (Regex + ML Fallback)
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

    // 3. Predict Category (ML)
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
