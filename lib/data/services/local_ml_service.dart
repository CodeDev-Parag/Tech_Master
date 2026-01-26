import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../../core/constants/app_constants.dart';

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

  // Pre-training dataset (The "Different Data Set" user asked for)
  // We can inject different "knowledge basics" here.
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

  /// Trains the model on a list of tasks AND the seed data
  void train(List<Task> userTasks) {
    _clearModel();

    // 1. Train on Seed Data (Base Knowledge)
    _seedTrainingData.forEach((text, category) {
      _trainSingle(text, category: category);
    });

    _seedPriorityData.forEach((text, priority) {
      _trainSingle(text, priority: priority);
    });

    // 2. Train on User Data (Personalization)
    for (var task in userTasks) {
      if (task.title.isNotEmpty) {
        _trainSingle(
          task.title + " " + (task.description ?? ""),
          category: task.categoryId,
          priority: task.priority,
        );
      }
    }

    print("ML Service Trained on ${_totalTasks} items.");
  }

  void _trainSingle(String text, {String? category, Priority? priority}) {
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
      // P(Category)
      // Let's use a standard Sum of Logs approach to avoid underflow
      double logProb = 0.0;
      final categoryTotalWords =
          _categoryWordCounts[category]?.values.fold(0, (a, b) => a + b) ?? 1;

      for (var word in tokens) {
        final wordCount = _categoryWordCounts[category]?[word] ?? 0;
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

  /// Exports the local training data as a JSON string
  /// This can be used for "Data Collection" (Federated or Centralized)
  String exportTrainingData() {
    final buffer = StringBuffer();
    buffer.writeln('{"version": "1.0", "data": [');

    // We can't easily export the raw counts back to original sentences without storing them.
    // However, since the prompt asks "how can i collect that data", usually this involves
    // sending the *raw* inputs (anonymized) to a server.
    // Since we don't store raw inputs in this simple ML model (only counts),
    // we will simulate the export of the "Learned Model" itself, which is also valuable.

    // Actually, to be useful for "different users", we'd want the weights.
    // Let's export the model weights (Category Word Counts).

    // Export Category Model
    // Format: {"type": "category_model", "category": "Personal", "word": "milk", "count": 5}

    var first = true;
    _categoryWordCounts.forEach((category, wordCounts) {
      wordCounts.forEach((word, count) {
        if (!first) buffer.writeln(',');
        buffer.write(
            '  {"type": "category_model", "category": "$category", "word": "$word", "count": $count}');
        first = false;
      });
    });

    _priorityWordCounts.forEach((priority, wordCounts) {
      wordCounts.forEach((word, count) {
        if (!first) buffer.writeln(',');
        buffer.write(
            '  {"type": "priority_model", "priority": "${priority.toString().split('.').last}", "word": "$word", "count": $count}');
        first = false;
      });
    });

    buffer.writeln('\n]}');
    return buffer.toString();
  }

  /// Syncs the current model weights to the collection backend
  Future<void> syncTrainingData() async {
    final data = exportTrainingData();
    try {
      await http.post(
        Uri.parse(AppConstants.dataCollectionServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: data,
      );
      print('Training data synced to backend!');
    } catch (e) {
      print('Failed to sync training data: $e');
    }
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
