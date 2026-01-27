import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

class LocalNlpIntent {
  final String category;
  final String intent;
  final String scenario;

  LocalNlpIntent({
    required this.category,
    required this.intent,
    required this.scenario,
  });

  factory LocalNlpIntent.fromJson(Map<String, dynamic> json) {
    return LocalNlpIntent(
      category: json['category'] ?? 'General',
      intent: json['intent'] ?? 'unknown',
      scenario: json['scenario'] ?? '',
    );
  }
}

class LocalNlpService {
  List<LocalNlpIntent> _dataset = [];
  final Map<String, Map<String, int>> _intentWeights = {};
  final Set<String> _vocab = {};

  final Map<String, int> _intentUsage = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/productivity_dataset.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _dataset = jsonList.map((j) => LocalNlpIntent.fromJson(j)).toList();

      _buildIndex();

      // Load usage bias from Hive
      final box = await Hive.openBox(AppConstants.aiWeightsBox);
      final savedUsage = box.get('nlp_usage');
      if (savedUsage != null) {
        final decoded = json.decode(savedUsage as String);
        (decoded as Map)
            .forEach((k, v) => _intentUsage[k.toString()] = v as int);
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing LocalNlpService: $e');
    }
  }

  Future<void> _saveUsage() async {
    final box = await Hive.openBox(AppConstants.aiWeightsBox);
    await box.put('nlp_usage', json.encode(_intentUsage));
  }

  void _buildIndex() {
    for (var item in _dataset) {
      final tokens = _tokenize(item.scenario);
      final key = '${item.category}|${item.intent}';

      _intentWeights[key] ??= {};
      for (var token in tokens) {
        _vocab.add(token);
        _intentWeights[key]![token] = (_intentWeights[key]![token] ?? 0) + 1;
      }
    }
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !_stopWords.contains(t))
        .toList();
  }

  /// Finds the best matching intent for a given query
  String predictIntent(String query) {
    if (!_isInitialized || _intentWeights.isEmpty) return "General|unknown";

    final tokens = _tokenize(query);
    if (tokens.isEmpty) return "General|unknown";

    String bestIntent = "General|unknown";
    double maxScore = -1.0;

    _intentWeights.forEach((intentKey, weights) {
      double score = 0;
      for (var token in tokens) {
        if (weights.containsKey(token)) {
          // Base frequency scoring
          score += weights[token]!;
        }
      }

      // Add user bias (Adaptive Learning)
      // Every time an intent is used, it gets a small boost
      final usageBoost = (_intentUsage[intentKey] ?? 0) * 0.1;
      score += usageBoost;

      if (score > maxScore) {
        maxScore = score;
        bestIntent = intentKey;
      }
    });

    // Record usage for next time (Feedback loop)
    if (bestIntent != "General|unknown") {
      _intentUsage[bestIntent] = (_intentUsage[bestIntent] ?? 0) + 1;
      _saveUsage();
    }

    return bestIntent;
  }

  /// Gets a response based on category and intent
  String getResponse(String intentKey) {
    final parts = intentKey.split('|');
    final category = parts[0];
    final intent = parts[1];

    switch (category) {
      case 'Work':
        return _getWorkResponse(intent);
      case 'Tools':
        return _getToolsResponse(intent);
      case 'Habits':
        return _getHabitsResponse(intent);
      case 'Time Management':
        return _getTimeManagementResponse(intent);
      case 'Mindset':
        return _getMindsetResponse(intent);
      default:
        return "I've analyzed your request. Focusing on your productivity architecture, I recommend breaking this down into smaller, atomic tasks to maintain momentum.";
    }
  }

  String _getWorkResponse(String intent) {
    if (intent.contains('prioritization')) {
      return "Prioritization is the foundation of high output. Use the Eisenhower Matrix: Focus on Important/Non-Urgent tasks to prevent future crises. Identify your 'One Big Thing' for today.";
    }
    if (intent.contains('optimization')) {
      return "To optimize your workflow, audit your recurrent tasks. Any task done more than 3 times should be templated or automated. Efficiency is doing things right; effectiveness is doing the right things.";
    }
    return "In the realm of Work, clarity is power. Ensure every task has a defined 'Done' state and a clear next physical action.";
  }

  String _getToolsResponse(String intent) {
    return "Tools should serve your system, not define it. Whether you use digital apps or analog journals, the principle remains: Minimize friction and ensure your 'Second Brain' is easily searchable.";
  }

  String _getHabitsResponse(String intent) {
    return "Mastery is the result of consistent habits. Use 'Habit Stacking': Attach a new habit to an existing one. Remember, the goal is not to be perfect, but to be 1% better every day.";
  }

  String _getTimeManagementResponse(String intent) {
    return "Time management is actually energy management. Use Time-Blocking for deep work and 'Eating the Frog' (doing the hardest task first) to optimize your peak energy hours.";
  }

  String _getMindsetResponse(String intent) {
    return "A growth mindset is essential for an Architect. View obstacles as data points for optimization. Replace 'I have to' with 'I get to', and maintain focus on long-term mastery.";
  }

  static const Set<String> _stopWords = {
    'the',
    'and',
    'to',
    'of',
    'a',
    'in',
    'is',
    'for',
    'on',
    'with',
    'at',
    'by',
    'an',
    'be',
    'this',
    'that',
    'how',
    'can',
    'improve',
    'using',
    'techniques'
  };
}

final localNlpServiceProvider = Provider<LocalNlpService>((ref) {
  return LocalNlpService();
});
