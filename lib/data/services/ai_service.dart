import 'package:flutter/material.dart';
import '../models/task.dart';
import 'local_ml_service.dart';
import 'local_nlp_service.dart';
import 'dart:async';
import '../models/note.dart';

class ParsedTask {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final Priority? priority;
  final String? category;
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
  final LocalNlpService _nlpService;

  AIService(this._mlService, this._nlpService, _);

  // Always true now as we are running locally
  bool get isConfigured => true;
  bool get isLLMReady => true;

  Future<void> init() async {
    await _mlService.init();
    await _nlpService.init();
    notifyListeners();
  }

  // Legacy stubs for compatibility
  Future<void> initializeLLM(String modelPath) async {}
  Future<bool> checkServerHealth() async => true;
  Future<void> syncData(List<Task> tasks, List<Note> notes) async {}

  Future<void> trainModel(List<Task> tasks) async {
    await _mlService.train(tasks);
    notifyListeners();
  }

  Future<void> learnFromTask(Task task) async {
    await _mlService.learnFromTask(task);
    notifyListeners();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  /// Chat response using local NLP engine
  Future<String> chat(String message, {String? context}) async {
    if (!_nlpService.isInitialized) await _nlpService.init();

    final timeGreeting = _getTimeGreeting();

    // Greeting/Generic handling
    final lower = message.toLowerCase();
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return "$timeGreeting! I am your Local Productivity Architect. I'm powered by a custom productivity knowledge base to help you optimize your workflow offline. No data leaves your device. How can I help you architect your success today?";
    }

    // Predictive Intent Matching
    final intentKey = _nlpService.predictIntent(message);
    return _nlpService.getResponse(intentKey);
  }

  /// Streaming chat response using simulated typing
  Stream<String> chatStream(String message, {bool isLocalMode = true}) async* {
    final fullResponse = await chat(message);

    // Simulate typing effect for a premium feel
    final words = fullResponse.split(' ');
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield "$word ";
    }
  }

  /// Parses natural language input using Regex AND Local ML
  Future<ParsedTask> parseNaturalLanguage(String input) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 200));

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

    // 2. Detect Time
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
      title = title.replaceAll(timeMatch.group(0)!, '');
    }

    // Resolve DateTime
    if (dueDate != null && dueTime != null) {
      dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, dueTime.hour,
          dueTime.minute);
    } else if (dueDate == null && dueTime != null) {
      final todayTime =
          DateTime(now.year, now.month, now.day, dueTime.hour, dueTime.minute);
      dueDate = todayTime.isBefore(now)
          ? todayTime.add(const Duration(days: 1))
          : todayTime;
    }

    // 3. Priority & Category (ML)
    priority = _mlService.predictPriority(title);
    final predictedCategory = _mlService.predictCategory(title);

    return ParsedTask(
      title: title.trim(),
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
    final lower = taskTitle.toLowerCase();
    if (lower.contains('learn') || lower.contains('study')) {
      return [
        'Define learning goals',
        'Gather resources',
        'Schedule deep work session',
        'Practice application'
      ];
    }
    return ['Analyze requirements', 'Identify first step', 'Execute', 'Review'];
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

    return ProductivityInsight(
      summary: completionRate > 0.7
          ? 'Excellent momentum!'
          : 'Focus on closing open loops.',
      tips: ['Break down large tasks', 'Avoid multitasking'],
      productivityScore: completionRate * 100,
      recommendation: completionRate < 0.5
          ? 'Pick one small task to finish now.'
          : 'Schedule deep work for tomorrow.',
    );
  }
}
