import 'package:flutter/material.dart';
import '../models/task.dart';
import 'local_ml_service.dart';
import '../../core/services/llm_service.dart';

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
  final LlmService _llmService = LlmService();

  AIService(this._mlService);

  static const String systemRole = """
You are the Task Master Architect, a senior software engineer and personal productivity coach. Your goal is to help me build the "Task Master" app—a goal-aware "Life OS"—while simultaneously guiding me to master any skill or subject I choose.

Core Project Context:
Project Name: Task Master (evolved from "Life OS").
Objective: A task management system that breaks down high-level "Life Goals" into atomic, daily actionable To-Do lists.
Themes: High efficiency, hierarchical task structures, and an optional "Goku-inspired" aesthetic for the UI.

My Technical Profile:
Background: Java and Android development.
Current Focus: Master of Web Tech, JavaScript, and anything else that helps build the ultimate Life OS.

Operational Rules:
1. Atomic Planning: Whenever I ask for a plan or To-Do list, break it into steps that take <30 mins.
2. Code/Technical Integration: Relate new concepts back to my existing knowledge (like Java/Android) whenever possible.
3. Goal-Awareness: Every task should serve the ultimate goal of finishing the Task Master app or improving my life.
4. Universal Learning: Apply a 3-phase progression to any subject: Phase 1: Core Fundamentals, Phase 2: Practical Application/Persistence, Phase 3: Mastery & Async Integration.
""";

  // Always true now as we are running locally
  bool get isConfigured => true;

  Future<void> init() async {
    // Attempt to initialize LLM with a default path if it exists
    // Path recommended by Google AI Edge Gallery for local testing
    const defaultModelPath = '/data/local/tmp/gemma-2b-it-cpu-int4.bin';
    await _llmService.initialize(defaultModelPath);
  }

  Future<void> initializeLLM(String modelPath) async {
    await _llmService.initialize(modelPath);
    notifyListeners();
  }

  bool get isLLMReady => _llmService.isInitialized;

  /// Trains the local AI model on the user's dataset
  void trainModel(List<Task> tasks) {
    _mlService.train(tasks);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    // No-op
  }

  String? get apiKey => null;

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  /// Simulates a chat response using local logic
  Future<String> chat(String message, {String? context}) async {
    // 1. Try Local LLM (Gemma) first if ready
    if (isLLMReady) {
      final response = await _llmService.generateResponse(message);
      if (response != null && response.isNotEmpty) {
        return response;
      }
    }

    // 2. Fallback to rule-based logic (original Architect persona)
    await Future.delayed(const Duration(milliseconds: 600));

    final lower = message.toLowerCase();
    final timeGreeting = _getTimeGreeting();

    // Persona Greeting
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) {
      return "$timeGreeting! I am the Task Master Architect. I'm ready to help you architect your Life OS and master any skill you desire along the way. Whether it's the depths of JavaScript, the nuances of design, or any other world of knowledge, I will break it down for you. Which part of our Task Master project or what new subject shall we tackle first?";
    }

    // Universal Learning Path
    if (lower.contains('learn') ||
        lower.contains('study') ||
        lower.contains('how to')) {
      // Extract subject if possible (heuristic)
      String subject = "this new subject";
      if (lower.contains('learn ')) {
        subject = message.split('learn ').last.replaceFirst('?', '').trim();
      } else if (lower.contains('study ')) {
        subject = message.split('study ').last.replaceFirst('?', '').trim();
      }

      return "Excellent choice. To master **$subject**, we will follow my 3-phase Universal Learning Path:\n1. **Phase 1: Fundamentals**: Grasping the core axioms and syntax of the subject.\n2. **Phase 2: Application**: Bringing logic into reality through persistence and projects.\n3. **Phase 3: Integration**: Mastering complexity and async flows.\n\nI will generate atomic tasks (<30 mins) for you as we progress. Shall we start with Phase 1 for $subject?";
    }

    // Productivity and Procrastination
    if (lower.contains('procrastinat') ||
        lower.contains('lazy') ||
        lower.contains('put off')) {
      return "The Architect's advice: Procrastination is often a fear of starting. Let's use **Atomic Planning**. I'll break your current hurdle into <30 min blocks. If you have an impulse to act, move within 5 seconds! Go check the 'Procrastination Combat' section.";
    }

    if (lower.contains('focus') || lower.contains('distraction')) {
      return "Focus is the currency of mastery. Schedule 90-minute blocks of Deep Work. The Pomodoro timer in Task Master is your 'Focus Room'. Use it to build that discipline.";
    }

    if (lower.contains('pattern') || lower.contains('habit')) {
      return "Analyzing your productivity patterns shows you're most efficient when tasks are atomic. Let's keep our planning granular to maximize your output.";
    }

    if (lower.contains('note') || lower.contains('write')) {
      return "Capture your architectural decisions in the Notes section. You can export them as PDFs—perfect for project documentation for your next hackathon!";
    }

    if (lower.contains('help') || lower.contains('what can you do')) {
      return "As your Architect, I can:\n1. Break down 'Life Goals' into atomic tasks.\n2. Guide your Mastery Path for any subject (Phase 1-3).\n3. Provide logic bridges between your existing knowledge and new fields.\n4. Design combat strategies for procrastination.";
    }

    // Default fallback
    return "Understood. As your Architect, I suggest we keep our focus sharp. How does this request fit into our current development phase or your goal of building the ultimate Task Master app?";
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
    if (lower.contains('learn') ||
        lower.contains('study') ||
        lower.contains('master')) {
      return [
        'Phase 1: Research core fundamentals and axioms',
        'Phase 2: Setup practice environment/workspace',
        'Phase 3: Complete first practical application project',
        'Phase 4: Review and iterate on complex concepts'
      ];
    }

    return [
      'Analyze requirements',
      'Break down into atomic steps',
      'Execute Phase 1',
      'Review outcomes'
    ];
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
