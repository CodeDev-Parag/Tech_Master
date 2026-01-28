import 'package:flutter/material.dart';
import '../models/task.dart';
import 'local_ml_service.dart';
import 'local_nlp_service.dart';
import 'dart:async';
import '../models/note.dart';
import '../repositories/task_repository.dart';
import '../repositories/settings_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';

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
  final SettingsRepository _settingsRepository;
  final TaskRepository _taskRepository;

  AIService(this._mlService, this._nlpService, this._settingsRepository,
      this._taskRepository);

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
  Future<bool> checkServerHealth() async {
    return true; // Always true in purely local mode
  }

  Future<void> syncData(List<Task> tasks, List<Note> notes) async {
    // 1. Train local ML model
    await trainModel(tasks);
    print('DEBUG: Local AI model updated with ${tasks.length} tasks.');

    // 2. Sync to Cloud Backend (Gemini)
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.backendBaseUrl}/train'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tasks': tasks
              .map((t) => {
                    'title': t.title,
                    'description': t.description ?? '',
                    'status': t.status.name,
                    'priority': t.priority.name,
                    'date': t.dueDate?.toIso8601String() ?? '',
                  })
              .toList(),
          'notes': notes.map((n) => n.content).toList(),
        }),
      );

      if (response.statusCode == 200) {
        print('DEBUG: Successfully synced data to Cloud AI.');
      } else {
        print(
            'DEBUG: Cloud AI sync failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error syncing to Cloud AI: $e');
    }
  }

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

  /// Chat response - Fully Local
  /// Chat response - Fully Local
  Future<String> chat(String message,
      {List<Task> tasks = const [],
      List<Note> notes = const [],
      List<dynamic> sessions = const [],
      bool isProMode = false}) async {
    if (!_nlpService.isInitialized) await _nlpService.init();
    final timeGreeting = _getTimeGreeting();
    final lower = message.toLowerCase();

    // 1. Greeting
    if (lower.contains('hello') ||
        lower.contains('hi ') ||
        lower == 'hi' ||
        lower.contains('hey')) {
      if (isProMode) {
        return "$timeGreeting! I am your Local Productivity Architect. I have full access to your ${tasks.length} tasks, ${notes.length} notes and ${sessions.length} scheduled classes. How can I help you organize today?";
      } else {
        return "$timeGreeting! I am your Local AI Assistant. I can help you manage tasks and notes. Unlock Pro Mode for advanced daily planning capabilities.";
      }
    }

    // 2. Schedule Planning (Pro Mode)
    if ((lower.contains('plan') &&
            (lower.contains('day') || lower.contains('schedule'))) ||
        (lower.contains('productivity') && lower.contains('increase'))) {
      if (!isProMode) {
        return "This is a Pro Mode feature. Please unlock Pro Mode in Settings to enable advanced schedule planning and productivity optimization.";
      }

      if (sessions.isEmpty && tasks.isEmpty) {
        return "I can help you plan, but I need some data first. Try adding your timetable or some tasks.";
      }

      final now = DateTime.now();

      // Simple algorithm: Find gaps between classes and fill with tasks
      final List<String> plan = [];
      plan.add("Here is a productivity plan for the rest of your day:");

      int currentHour = now.hour;
      if (currentHour < 8) currentHour = 8; // Start day at 8 AM if early
      if (currentHour > 20) {
        return "The day is almost over! Take some rest and plan for tomorrow.";
      }

      // Sort items by time
      // This is a simplified "Pro" algorithm
      for (int i = currentHour; i < 21; i++) {
        final hourStart = i;
        final hourEnd = i + 1;

        // Check if busy with class
        final busyClass = sessions.cast<dynamic>().firstWhere((s) {
          // Assuming s has startTimeHour property (dynamic check)
          return s.startTimeHour <= i && s.endTimeHour > i;
        }, orElse: () => null);

        if (busyClass != null) {
          plan.add(
              "• **$hourStart:00 - $hourEnd:00**: Attend Class: ${busyClass.subjectName}");
        } else {
          // Free slot!
          // Find a task
          final task = tasks.firstWhere(
              (t) =>
                  t.status != TaskStatus.completed &&
                  (t.priority == Priority.high ||
                      t.priority == Priority.urgent),
              orElse: () => Task(
                  id: 'temp',
                  title: 'Review notes or take a break',
                  status: TaskStatus.pending,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  checklist: [],
                  priority: Priority.low) // Dummy
              );

          if (task.id != 'temp') {
            plan.add(
                "• **$hourStart:00 - $hourEnd:00**: Work on \"${task.title}\" (High Priority)");
          } else {
            plan.add(
                "• **$hourStart:00 - $hourEnd:00**: Deep Work / Study Session or Review Notes");
          }
        }
      }

      return plan.join('\n');
    }

    // 3. Data Queries (Task Awareness)
    if (lower.contains('task') ||
        lower.contains('todo') ||
        lower.contains('doing')) {
      if (tasks.isEmpty) {
        return "You don't have any tasks right now. Try adding one!";
      }

      if (lower.contains('high') || lower.contains('urgent')) {
        final highPriority = tasks
            .where((t) =>
                t.status != TaskStatus.completed &&
                (t.priority == Priority.high || t.priority == Priority.urgent))
            .take(5)
            .toList();

        if (highPriority.isEmpty) {
          return "Good news! You have no pending high-priority tasks.";
        } else {
          final list = highPriority
              .map((t) => "• ${t.title} (${t.priority.name})")
              .join('\n');
          return "Here are your top priority tasks:\n$list";
        }
      }

      if (lower.contains('overdue')) {
        final now = DateTime.now();
        final overdue = tasks
            .where((t) =>
                t.status != TaskStatus.completed &&
                t.dueDate != null &&
                t.dueDate!.isBefore(now))
            .take(5)
            .toList();

        if (overdue.isEmpty) return "You're on track! No overdue tasks.";
        final list = overdue
            .map((t) =>
                "• ${t.title} (Due: ${t.dueDate.toString().split(' ')[0]})")
            .join('\n');
        return "You have these overdue tasks:\n$list";
      }

      // General pending tasks summary
      final pending =
          tasks.where((t) => t.status != TaskStatus.completed).take(5).toList();
      final list = pending.map((t) => "• ${t.title}").join('\n');
      return "You have ${tasks.where((t) => t.status != TaskStatus.completed).length} pending tasks. Here are the next few:\n$list";
    }

    // 4. Data Queries (Note Awareness)
    if (lower.contains('note') ||
        lower.contains('remember') ||
        lower.contains('summary')) {
      if (notes.isEmpty) return "Your notebook is empty.";

      // Keyword search in notes
      final keywords = lower
          .replaceAll('note', '')
          .replaceAll('show', '')
          .replaceAll('find', '')
          .replaceAll('about', '')
          .trim()
          .split(' ');

      if (keywords.first.isNotEmpty) {
        final matches = notes
            .where((n) {
              return keywords.any((k) =>
                  n.content.toLowerCase().contains(k) ||
                  n.title.toLowerCase().contains(k));
            })
            .take(3)
            .toList();

        if (matches.isEmpty) {
          return "I couldn't find any notes matching '$lower'.";
        }
        final list = matches.map((n) => "• ${n.title}").join('\n');
        return "Found these notes:\n$list";
      }

      // Default notes summary
      return "You have ${notes.length} notes. Ask me about a specific topic!";
    }

    // 5. Explicit Commands (Mark as Complete)
    if (lower.contains('mark') &&
        (lower.contains('complete') || lower.contains('done'))) {
      // Extract task name: "mark [buy milk] as complete"
      String taskName = lower
          .replaceAll('mark', '')
          .replaceAll('this task', '')
          .replaceAll('task', '')
          .replaceAll('as', '')
          .replaceAll('complete', '')
          .replaceAll('done', '')
          .trim();

      if (taskName.isNotEmpty) {
        // Find task
        try {
          // Flexible matching
          final taskToUpdate = tasks.firstWhere(
            (t) =>
                t.title.toLowerCase().contains(taskName) &&
                t.status != TaskStatus.completed,
          );

          await _taskRepository.toggleTaskStatus(taskToUpdate.id);
          return "✅ Task marked as complete: ${taskToUpdate.title}";
        } catch (e) {
          try {
            // If fuzzy match failed, try matching ANY task containing the name (even completed ones, to be smart)
            final taskToUpdate = tasks.firstWhere(
              (t) => t.title.toLowerCase().contains(taskName),
            );
            if (taskToUpdate.status == TaskStatus.completed) {
              return "Task '${taskToUpdate.title}' is already completed!";
            }
          } catch (_) {}

          return "I couldn't find a pending task matching \"$taskName\". Please check the exact name.";
        }
      } else {
        return "Which task would you like to mark as complete?";
      }
    }

    // 6. Fallback to NLP Intent Prediction
    final intentKey = _nlpService.predictIntent(message);
    return _nlpService.getResponse(intentKey);
  }

  // Conversation History Buffer for Context Awareness
  final List<String> _conversationHistory = [];

  // Enhanced Chat with Context
  Future<String> chatWithContext(String message,
      {List<Task> tasks = const [],
      List<Note> notes = const [],
      List<dynamic> sessions = const [],
      bool isProMode = false}) async {
    // Add User Message to History
    _conversationHistory.add("User: $message");
    if (_conversationHistory.length > 10) {
      _conversationHistory.removeAt(0); // Keep last 10 turns
    }

    // Check for "Reply Itself" / Follow-up triggers
    final lower = message.toLowerCase();
    if (lower.contains('tell me more') ||
        lower.contains('continue') ||
        lower.contains('explain')) {
      // Ideally this would use an LLM, but for local logic we check the last system response
      final lastResponse =
          _conversationHistory.where((m) => m.startsWith("AI:")).lastOrNull;
      if (lastResponse != null) {
        if (lastResponse.contains('pending tasks')) {
          // Elaborate on tasks
          return "You have tasks like '${tasks.firstOrNull?.title}'. You should prioritize the urgent ones.";
        }
      }
    }

    // Get Base Response
    final response = await chat(message,
        tasks: tasks, notes: notes, sessions: sessions, isProMode: isProMode);

    // Add AI Response to History
    _conversationHistory.add("AI: $response");
    if (_conversationHistory.length > 10) _conversationHistory.removeAt(0);

    return response;
  }

  /// Streaming chat response - Handles both Local and Cloud (Gemini)
  Stream<String> chatStream(String message,
      {List<Task> tasks = const [],
      List<Note> notes = const [],
      List<dynamic> sessions = const [],
      bool isProMode = false,
      bool isLocalMode = true}) async* {
    if (isLocalMode) {
      // Calculate response synchronously first
      final fullResponse = await chatWithContext(message,
          tasks: tasks, notes: notes, sessions: sessions, isProMode: isProMode);

      // Stream it
      final words = fullResponse.split(' ');
      for (var i = 0; i < words.length; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
        yield "${words[i]} ";
      }
    } else {
      // CLOUD Path
      yield* chatStreamCloud(message);
    }
  }

  /// Cloud Chat Stream (Gemini Backend)
  Stream<String> chatStreamCloud(String message) async* {
    try {
      final client = http.Client();
      final request = http.Request(
        'POST',
        Uri.parse('${AppConstants.backendBaseUrl}/chat'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'message': message,
        'context_window': 10,
      });

      final response =
          await client.send(request).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await for (var line in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.trim().isEmpty) continue;
          try {
            final data = json.decode(line);
            if (data.containsKey('token')) {
              yield data['token'];
            }
          } catch (e) {
            print('DEBUG: Error parsing chat stream line: $e');
          }
        }
      } else if (response.statusCode == 503) {
        yield "AI is waking up on Render. Please try again in 30 seconds...";
      } else {
        yield "Cloud AI is currently unavailable (Status: ${response.statusCode}). Using local fallback...";
      }
    } catch (e) {
      print('DEBUG: Cloud Chat Error: $e');
      yield "Error connecting to Cloud AI. Please check your internet connection.";
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

    // Time-based context
    final hour = DateTime.now().hour;
    String timeContext = '';
    String timeAdvice = '';

    if (hour < 12) {
      timeContext = 'Good Morning!';
      timeAdvice = 'Tackle your hardest task first (Eat the Frog).';
    } else if (hour < 17) {
      timeContext = 'Good Afternoon!';
      timeAdvice = 'Maintain your momentum or take a short break.';
    } else {
      timeContext = 'Good Evening!';
      timeAdvice = 'Wrap up for the day and plan for tomorrow.';
    }

    String summary = '';
    if (completionRate > 0.7) {
      summary = '$timeContext You are crushing it today!';
    } else if (completionRate > 0.3) {
      summary = '$timeContext Making steady progress.';
    } else {
      summary = '$timeContext Let\'s get some tasks done.';
    }

    return ProductivityInsight(
      summary: summary,
      tips: [timeAdvice, 'Focus on one thing at a time'],
      productivityScore: completionRate * 100,
      recommendation: completionRate < 0.5
          ? 'Pick one small task to finish now.'
          : 'Review your upcoming schedule.',
    );
  }
}
