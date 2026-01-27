import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/task.dart';
import '../../data/models/category.dart';
import '../../data/models/user_stats.dart';
import '../../data/services/gamification_service.dart';
import '../../data/services/pattern_analysis_service.dart';
import '../../data/services/local_ml_service.dart';
import '../../data/models/note.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/services/note_export_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/local_nlp_service.dart';

// Repository providers
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final noteExportServiceProvider = Provider<NoteExportService>((ref) {
  return NoteExportService();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final localMLServiceProvider = Provider<LocalMLService>((ref) {
  return LocalMLService();
});

final aiServiceProvider = ChangeNotifierProvider<AIService>((ref) {
  final mlService = ref.watch(localMLServiceProvider);
  final nlpService = ref.watch(localNlpServiceProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final service = AIService(mlService, nlpService, settingsRepo);
  service.init();
  return service;
});

final gamificationServiceProvider =
    StateNotifierProvider<GamificationService, UserStats>((ref) {
  return GamificationService();
});

final patternAnalysisServiceProvider = Provider<PatternAnalysisService>((ref) {
  return PatternAnalysisService();
});

// Task providers
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier(
    ref.watch(taskRepositoryProvider),
    ref,
  );
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskRepository _repository;
  final Ref _ref;

  TasksNotifier(this._repository, this._ref) : super([]) {
    loadTasks();
  }

  void loadTasks() {
    state = _repository.getAllTasks();
  }

  List<Task> get todaysTasks => _repository.getTodaysTasks();
  List<Task> get overdueTasks => _repository.getOverdueTasks();
  List<Task> get upcomingTasks => _repository.getUpcomingTasks();

  Future<void> addTask(Task task) async {
    await _repository.addTask(task);
    loadTasks();
    _triggerLearning();
  }

  Future<void> updateTask(Task task) async {
    await _repository.updateTask(task);
    loadTasks();
    _triggerLearning();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    loadTasks();
    _triggerLearning();
  }

  Future<void> toggleTaskStatus(String id) async {
    await _repository.toggleTaskStatus(id);
    loadTasks();

    // Check if the task was just completed
    final task = state.firstWhere((t) => t.id == id);
    if (task.status == TaskStatus.completed) {
      _ref.read(gamificationServiceProvider.notifier).completeTask();
    }

    _triggerLearning();
  }

  Future<void> toggleSubTask(String taskId, String subTaskId) async {
    await _repository.toggleSubTask(taskId, subTaskId);
    loadTasks();
  }

  void _triggerLearning() {
    // Re-train Local Model with current tasks to ensure personalization
    final tasks = state;
    final aiService = _ref.read(aiServiceProvider);
    aiService.trainModel(tasks);
  }

  List<Task> filterByStatus(TaskStatus status) {
    return state.where((t) => t.status == status).toList();
  }

  List<Task> filterByCategory(String categoryId) {
    return state.where((t) => t.categoryId == categoryId).toList();
  }

  List<Task> filterByPriority(Priority priority) {
    return state.where((t) => t.priority == priority).toList();
  }

  Map<String, dynamic> get statistics => _repository.getStatistics();
  List<Map<String, dynamic>> get completionHistory =>
      _repository.getCompletionHistory();
}

// Category providers
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier(ref.watch(categoryRepositoryProvider));
});

class CategoriesNotifier extends StateNotifier<List<Category>> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super([]) {
    loadCategories();
  }

  void loadCategories() {
    state = _repository.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    await _repository.addCategory(category);
    loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    loadCategories();
  }

  Category? getCategoryById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Theme provider
final themeModeProvider =
    StateProvider<bool>((ref) => true); // true = dark mode

// Settings providers
// Settings providers
final aiConfiguredProvider = StateProvider<bool>((ref) => false);

final autoCollectProvider =
    StateNotifierProvider<AutoCollectNotifier, bool>((ref) {
  return AutoCollectNotifier(ref.watch(settingsRepositoryProvider));
});

class AutoCollectNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;
  AutoCollectNotifier(this._repo) : super(_repo.continuousLearningEnabled);

  void toggle(bool value) {
    state = value;
    _repo.setContinuousLearning(value);
  }
}

final aiModeProvider = StateNotifierProvider<AiModeNotifier, bool>((ref) {
  return AiModeNotifier(ref.watch(settingsRepositoryProvider));
});

class AiModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;
  AiModeNotifier(this._repo) : super(_repo.isLocalLlmMode);

  void toggle(bool isLocal) {
    state = isLocal;
    _repo.setLocalLlmMode(isLocal);
  }
}

final serverIpProvider = StateNotifierProvider<ServerIpNotifier, String>((ref) {
  return ServerIpNotifier(ref.watch(settingsRepositoryProvider));
});

class ServerIpNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;
  ServerIpNotifier(this._repo) : super(_repo.serverIp);

  void update(String ip) {
    state = ip;
    _repo.setServerIp(ip);
  }
}

final customServerModeProvider =
    StateNotifierProvider<CustomServerModeNotifier, bool>((ref) {
  return CustomServerModeNotifier(ref.watch(settingsRepositoryProvider));
});

class CustomServerModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;
  CustomServerModeNotifier(this._repo) : super(_repo.useCustomServer);

  void toggle(bool enabled) {
    state = enabled;
    _repo.setUseCustomServer(enabled);
  }
}

// Note providers
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier(ref.watch(noteRepositoryProvider));
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final NoteRepository _repository;

  NotesNotifier(this._repository) : super([]) {
    loadNotes();
  }

  void loadNotes() {
    state = _repository.getAllNotes();
  }

  Future<void> addNote(Note note) async {
    await _repository.addNote(note);
    loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _repository.updateNote(note);
    loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    loadNotes();
  }
}
