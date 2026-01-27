import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../../core/constants/app_constants.dart';
import 'dart:convert';

// Simple Naive Bayes Classifier for Categories and Priorities
class LocalMLService {
  // Vocabulary: Word -> Global Count
  final Map<String, int> _vocab = {};

  // Category Model: Category -> Word -> Count
  final Map<String, Map<String, int>> _categoryWordCounts = {};
  final Map<String, int> _categoryTaskCounts = {};

  // Priority Model: Priority -> Word -> Count
  final Map<Priority, Map<String, int>> _priorityWordCounts = {};
  final Map<Priority, int> _priorityTaskCounts = {};

  int _totalTasks = 0;
  bool _isInitialized = false;

  // Pre-training dataset
  static const Map<String, String> _seedTrainingData = {
    'buy milk': 'Personal',
    'buy groceries': 'Personal',
    'gym': 'Health',
    'workout': 'Health',
    'meeting': 'Work',
    'email team': 'Work',
    'submit report': 'Work',
    'study math': 'Learning',
    'read book': 'Learning',
    'pay bills': 'Personal',
    'doctor appointment': 'Health',
    'coding project': 'Work',
    'clean house': 'Personal',
    'yoga': 'Health',
    'meditation': 'Health',
    'learn flutter': 'Learning',
    'call mom': 'Personal',
  };

  static const Map<String, Priority> _seedPriorityData = {
    'urgent meeting': Priority.urgent,
    'deadline today': Priority.urgent,
    'pay bills': Priority.high,
    'buy milk': Priority.medium,
    'watch movie': Priority.low,
    'relax': Priority.low,
    'check email': Priority.medium,
    'tax filing': Priority.high,
  };

  Future<void> init() async {
    if (_isInitialized) return;

    final box = await Hive.openBox(AppConstants.aiWeightsBox);
    final savedData = box.get('weights');

    if (savedData != null) {
      try {
        final decoded = json.decode(savedData as String);
        _loadFromMap(decoded);
      } catch (e) {
        print("Error loading AI weights: $e");
      }
    }

    _isInitialized = true;
  }

  void _loadFromMap(Map<String, dynamic> data) {
    // Load vocab
    if (data['vocab'] != null) {
      (data['vocab'] as Map).forEach((k, v) => _vocab[k.toString()] = v as int);
    }

    // Load Category Word Counts
    if (data['categoryWordCounts'] != null) {
      (data['categoryWordCounts'] as Map).forEach((cat, words) {
        _categoryWordCounts[cat.toString()] = {};
        (words as Map).forEach((word, count) {
          _categoryWordCounts[cat.toString()]![word.toString()] = count as int;
        });
      });
    }

    // Load Category Task Counts
    if (data['categoryTaskCounts'] != null) {
      (data['categoryTaskCounts'] as Map)
          .forEach((k, v) => _categoryTaskCounts[k.toString()] = v as int);
    }

    // Load Priority Word Counts
    if (data['priorityWordCounts'] != null) {
      (data['priorityWordCounts'] as Map).forEach((prior, words) {
        final priority = Priority.values.firstWhere(
            (e) => e.toString().split('.').last == prior,
            orElse: () => Priority.medium);
        _priorityWordCounts[priority] = {};
        (words as Map).forEach((word, count) {
          _priorityWordCounts[priority]![word.toString()] = count as int;
        });
      });
    }

    // Load Priority Task Counts
    if (data['priorityTaskCounts'] != null) {
      (data['priorityTaskCounts'] as Map).forEach((prior, count) {
        final priority = Priority.values.firstWhere(
            (e) => e.toString().split('.').last == prior,
            orElse: () => Priority.medium);
        _priorityTaskCounts[priority] = count as int;
      });
    }

    _totalTasks = data['totalTasks'] ?? 0;
  }

  Future<void> _saveToHive() async {
    final box = await Hive.openBox(AppConstants.aiWeightsBox);
    final data = {
      'vocab': _vocab,
      'categoryWordCounts': _categoryWordCounts,
      'categoryTaskCounts': _categoryTaskCounts,
      'priorityWordCounts': _priorityWordCounts
          .map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'priorityTaskCounts': _priorityTaskCounts
          .map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'totalTasks': _totalTasks,
    };
    await box.put('weights', json.encode(data));
  }

  /// Trains the model on a list of tasks AND the seed data
  Future<void> train(List<Task> userTasks) async {
    _clearModel();

    // 1. Train on Seed Data (Base Knowledge)
    _seedTrainingData.forEach((text, category) {
      _trainSingleInternal(text, category: category);
    });

    _seedPriorityData.forEach((text, priority) {
      _trainSingleInternal(text, priority: priority);
    });

    // 2. Train on User Data (Personalization)
    for (var task in userTasks) {
      if (task.title.isNotEmpty) {
        _trainSingleInternal(
          "${task.title} ${task.description ?? ""}",
          category: task.categoryId,
          priority: task.priority,
        );
      }
    }

    await _saveToHive();
    print("ML Service Trained on $_totalTasks items and persisted.");
  }

  /// Incremental learning from a single task (The Feedback Loop)
  Future<void> learnFromTask(Task task) async {
    _trainSingleInternal(
      "${task.title} ${task.description ?? ""}",
      category: task.categoryId,
      priority: task.priority,
    );
    await _saveToHive();
  }

  void _trainSingleInternal(String text,
      {String? category, Priority? priority}) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty) return;

    _totalTasks++;

    for (var word in tokens) {
      _vocab[word] = (_vocab[word] ?? 0) + 1;
    }

    if (category != null) {
      _categoryTaskCounts[category] = (_categoryTaskCounts[category] ?? 0) + 1;
      _categoryWordCounts[category] ??= {};
      for (var word in tokens) {
        _categoryWordCounts[category]![word] =
            (_categoryWordCounts[category]![word] ?? 0) + 1;
      }
    }

    if (priority != null) {
      _priorityTaskCounts[priority] = (_priorityTaskCounts[priority] ?? 0) + 1;
      _priorityWordCounts[priority] ??= {};
      for (var word in tokens) {
        _priorityWordCounts[priority]![word] =
            (_priorityWordCounts[priority]![word] ?? 0) + 1;
      }
    }
  }

  /// Predicts the most likely category for the given text
  String? predictCategory(String text) {
    if (_categoryTaskCounts.isEmpty) return null;

    final tokens = _tokenize(text);
    String? bestCategory;
    double maxProb = double.negativeInfinity;

    _categoryTaskCounts.forEach((category, count) {
      double logProb = 0.0;
      final categoryTotalWords =
          _categoryWordCounts[category]?.values.fold(0, (a, b) => a + b) ?? 1;

      for (var word in tokens) {
        final wordCount = _categoryWordCounts[category]?[word] ?? 0;
        // Laplace smoothing
        logProb += (wordCount + 1) / (categoryTotalWords + _vocab.length);
      }

      if (logProb > maxProb) {
        maxProb = logProb;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  /// Predicts the most likely priority
  Priority predictPriority(String text) {
    if (_priorityTaskCounts.isEmpty) return Priority.medium;

    final tokens = _tokenize(text);
    Priority bestPriority = Priority.medium;
    double maxProb = double.negativeInfinity;

    _priorityTaskCounts.forEach((priority, count) {
      double logProb = 0.0;
      final totalWords =
          _priorityWordCounts[priority]?.values.fold(0, (a, b) => a + b) ?? 1;

      for (var word in tokens) {
        final wordCount = _priorityWordCounts[priority]?[word] ?? 0;
        logProb += (wordCount + 1) / (totalWords + _vocab.length);
      }

      if (logProb > maxProb) {
        maxProb = logProb;
        bestPriority = priority;
      }
    });

    return bestPriority;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();
  }

  void _clearModel() {
    _vocab.clear();
    _categoryWordCounts.clear();
    _categoryTaskCounts.clear();
    _priorityWordCounts.clear();
    _priorityTaskCounts.clear();
    _totalTasks = 0;
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
    'that'
  };
}

final localMLServiceProvider = Provider<LocalMLService>((ref) {
  return LocalMLService();
});
