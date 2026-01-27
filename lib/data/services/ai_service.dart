import 'package:flutter/material.dart';
import '../models/task.dart';
import 'local_ml_service.dart';
import '../../core/services/llm_service.dart';
import '../repositories/settings_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/note.dart';

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
  final SettingsRepository _settingsRepo;
  final LlmService _llmService = LlmService();

  AIService(this._mlService, this._settingsRepo);

  static const String systemRole = """
You are a Productivity Architect, a high-performance coach focused on deep work, time-blocking, and the 80/20 rule.

Rules:
1. Always suggest actionable steps (Next Physical Actions).
2. Prioritize tasks using the Eisenhower Matrix logic.
3. Responses must be concise, using bullet points for scannability.
4. Discourage multi-tasking and emphasize single-tasking sessions.
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
  String? _lastHealthError;

  Future<bool> checkServerHealth() async {
    if (!_settingsRepo.useCustomServer) return false;
    _lastHealthError = null;
    try {
      String baseUrl = _settingsRepo.serverIp.trim();
      if (!baseUrl.startsWith('http')) {
        if (baseUrl.contains('render.com') ||
            baseUrl.contains('railway.app') ||
            baseUrl.contains('herokuapp.com')) {
          baseUrl = 'https://$baseUrl';
        } else {
          baseUrl = 'http://$baseUrl:8000';
        }
      }
      if (baseUrl.endsWith('/'))
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      debugPrint('AI_DEBUG: Health Check URL: $baseUrl/health');
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 45));

      debugPrint('AI_DEBUG: Health Check Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        _lastHealthError = "Status Code: ${response.statusCode}";
      }
      return response.statusCode == 200;
    } catch (e) {
      _lastHealthError = e.toString();
      debugPrint('AI_DEBUG: Health Check Failed: $e');
      return false;
    }
  }

  void trainModel(List<Task> tasks) {
    _mlService.train(tasks);
    notifyListeners();
  }

  Future<void> syncData(List<Task> tasks, List<Note> notes) async {
    if (!_settingsRepo.useCustomServer) return;

    try {
      String baseUrl = _settingsRepo.serverIp.trim();

      // Normalization: Ensure valid URI and handle Cloud domains
      if (!baseUrl.startsWith('http')) {
        final isCloud = baseUrl.contains('render.com') ||
            baseUrl.contains('railway.app') ||
            baseUrl.contains('herokuapp.com');

        if (isCloud) {
          baseUrl = 'https://$baseUrl'; // Default to HTTPS for cloud
        } else {
          baseUrl = 'http://$baseUrl:8000'; // Default to HTTP/Port for local
        }
      }

      // Remove trailing slash if present
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final url = Uri.parse('$baseUrl/train');

      final taskList = tasks
          .map((t) => {
                'title': t.title,
                'description': t.description ?? "",
                'status': t.status.toString().split('.').last,
                'priority': t.priority.toString().split('.').last,
                'date': t.dueDate?.toIso8601String() ?? "None",
              })
          .toList();

      final noteList = notes.map((n) => n.content).toList();

      final body = jsonEncode({
        'tasks': taskList,
        'notes': noteList,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Sync successful: ${response.body}');
      } else {
        debugPrint('Sync failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

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

  /// Streaming chat response
  Stream<String> chatStream(String message, {bool isLocalMode = true}) async* {
    if (_settingsRepo.useCustomServer) {
      debugPrint('AI_DEBUG: Server Mode Active');

      // Check health first to see if server is up
      final isAlive = await checkServerHealth();
      if (!isAlive) {
        final errorDetail =
            _lastHealthError != null ? "\nDetails: $_lastHealthError" : "";
        yield "⚠️ Server is currently unreachable or starting up. Please wait a moment and try again.$errorDetail";
        debugPrint('AI_DEBUG: Health Check failed, skipping chat request.');
        return;
      }

      // 1. Server Mode
      try {
        String baseUrl = _settingsRepo.serverIp.trim();
        debugPrint('AI_DEBUG: Raw Server Info: $baseUrl');

        if (!baseUrl.startsWith('http')) {
          if (baseUrl.contains('render.com') ||
              baseUrl.contains('railway.app') ||
              baseUrl.contains('herokuapp.com')) {
            baseUrl = 'https://$baseUrl';
          } else {
            baseUrl = 'http://$baseUrl:8000';
          }
        }
        if (baseUrl.endsWith('/')) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        }

        final url = Uri.parse('$baseUrl/chat');
        debugPrint('AI_DEBUG: Final Chat URL: $url');

        // Check if message is JSON (hack for direct RAG tests) or just text
        final body = jsonEncode({'message': message});
        debugPrint('AI_DEBUG: Request Body: $body');

        final request = http.Request('POST', url);
        request.headers['Content-Type'] = 'application/json';
        request.body = body;

        debugPrint('AI_DEBUG: Sending Request...');
        final client = http.Client();
        final response =
            await client.send(request).timeout(const Duration(seconds: 15));
        debugPrint('AI_DEBUG: Response Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint('AI_DEBUG: Response 200 - Reading Stream');
          final stream = response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          await for (final line in stream) {
            debugPrint('AI_DEBUG: Stream Line: $line');
            if (line.trim().isEmpty) continue;
            try {
              final data = jsonDecode(line);
              if (data['token'] != null) {
                yield data['token'];
              }
            } catch (e) {
              debugPrint('AI_DEBUG: JSON Parse Error: $e');
            }
          }
        } else if (response.statusCode == 503) {
          yield "⏳ AI Model is still downloading on the server. Please wait 1-2 minutes and try again.";
        } else {
          debugPrint('AI_DEBUG: Server Error Code: ${response.statusCode}');
          yield "❌ Server Error: ${response.statusCode}. Check if Render is still booting.";
        }
      } catch (e) {
        debugPrint('AI_DEBUG: Chat connection error: $e');
        yield "❌ Connection Error: Ensure your Render URL is correct and the server is 'Live'.";
      }
    } else if (isLocalMode && isLLMReady) {
      // 2. Local LLM (Gemma)
      yield* _llmService.generateResponseStream(message);
    } else {
      // 3. Fallback to Rule-Based Logic
      final fullResponse = await chat(message);

      // Simulate typing effect
      final words = fullResponse.split(' ');
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 50));
        yield "$word ";
      }
    }
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
