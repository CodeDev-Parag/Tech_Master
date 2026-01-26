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

  static const String systemRole = """
You are the Task Master Architect, a senior software engineer and personal productivity coach. Your goal is to help me build the "Task Master" app—a goal-aware "Life OS"—while simultaneously helping me master JavaScript.

Core Project Context:
Project Name: Task Master (evolved from "Life OS").
Objective: A task management system that breaks down high-level "Life Goals" into atomic, daily actionable To-Do lists.
Themes: High efficiency, hierarchical task structures, and an optional "Goku-inspired" aesthetic for the UI.

My Technical Profile:
Background: Java and Android development.
Current Focus: Mastering JavaScript and web technologies.

Operational Rules:
1. Atomic Planning: Whenever I ask for a plan or To-Do list, break it into steps that take <30 mins.
2. Code Integration: Use JavaScript for web-related examples, but relate logic back to Java/Android knowledge.
3. Goal-Awareness: Every task should serve the ultimate goal of finishing the Task Master app.
4. Learning Path: Phase 1: Fundamentals (Data/Logic), Phase 2: DOM/Persistence (Local Storage), Phase 3: Async JS (APIs).
""";

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

    // Persona Greeting
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return "Greetings! I am the Task Master Architect. I'm ready to help you architect your Life OS and master JavaScript along the way. Since you have a background in Java/Android, you'll find JS both familiar and uniquely powerful. Which specific part of the Task Master app or our 3-phase JS plan shall we tackle first?";
    }

    // JavaScript Learning Path
    if (lower.contains('javascript') ||
        lower.contains('js plan') ||
        lower.contains('learn')) {
      return "Excellent. We are following a 3-phase JS path:\n1. **Fundamentals**: Data/Logic (Think of this como Java syntax but looser!)\n2. **DOM/Persistence**: Local Storage (Like SharedPreferences but for the web)\n3. **Async JS**: APIs (Handling data streams)\n\nFor Task Master, we'll start with Phase 1 logic for our internal task structures.";
    }

    // Productivity and Procrastination
    if (lower.contains('procrastinat') ||
        lower.contains('lazy') ||
        lower.contains('put off')) {
      return "The Architect's advice: Procrastination is often a fear of starting. Let's use **Atomic Planning**. I'll break your current hurdle into <30 min blocks. If you have an impulse to act, move within 5 seconds! Go check the 'Procrastination Combat' section.";
    }

    if (lower.contains('focus') || lower.contains('distraction')) {
      return "Deep Work is key for a Senior Engineer. Schedule 90-minute blocks. The Pomodoro timer in Task Master is your 'Focus Room'. Use it to build that discipline.";
    }

    if (lower.contains('pattern') || lower.contains('habit')) {
      return "Analysis shows you're most productive early! Let's schedule high-complexity JS logic for your morning sessions to maximize your output.";
    }

    if (lower.contains('note') || lower.contains('write')) {
      return "Capture your architectural decisions in the Notes section. You can export them as PDFs—perfect for project documentation if you're hitting a hackathon soon!";
    }

    if (lower.contains('help') || lower.contains('what can you do')) {
      return "As your Architect, I can:\n1. Break down 'Life Goals' into atomic tasks.\n2. Guide your JavaScript learning path (Phase 1-3).\n3. Provide coding logic that bridges your Java/Android knowledge to Web/JS.\n4. Design combat strategies for procrastination.";
    }

    // Default fallback
    return "Understood. As your Architect, I suggest we keep our eyes on the goal: finishing Task Master. How does this request fit into our current development phase or your JS learning path?";
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
    } else {
      // Handle "in X days"
      final daysRegex = RegExp(r'in (\d+) days');
      final daysMatch = daysRegex.firstMatch(lowerInput);
      if (daysMatch != null) {
        final days = int.parse(daysMatch.group(1)!);
        dueDate = now.add(Duration(days: days));
        title = _removeKeyword(title, daysMatch.group(0)!);
      }
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
    if (lower.contains('javascript') || lower.contains('code')) {
      return [
        'Study basic syntax & variables',
        'Understand functions & scope',
        'Practice with arrays & objects',
        'Build a small project'
      ];
    }
    if (lower.contains('test') || lower.contains('exam')) {
      return [
        'Review study material',
        'Create mock questions',
        'Revise key concepts',
        'Take a practice test'
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
