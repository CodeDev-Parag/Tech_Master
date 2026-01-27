import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/models/task.dart';
import 'data/models/category.dart';
import 'data/models/user_stats.dart';
import 'data/models/note.dart';

import 'data/repositories/task_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/services/ai_service.dart';
import 'data/services/local_nlp_service.dart';
import 'data/repositories/note_repository.dart';

import 'data/models/timetable.dart';
import 'data/repositories/timetable_repository.dart';

import 'data/models/subject_attendance.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/settings_repository.dart';

import 'data/services/local_ml_service.dart';
import 'data/services/gamification_service.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(RecurrenceTypeAdapter());
  Hive.registerAdapter(SubTaskAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(UserStatsAdapter());
  Hive.registerAdapter(ClassSessionAdapter());
  Hive.registerAdapter(SubjectAttendanceAdapter());

  // Initialize repositories
  final taskRepo = TaskRepository();
  await taskRepo.init();

  final categoryRepo = CategoryRepository();
  await categoryRepo.init();

  final noteRepo = NoteRepository();
  await noteRepo.init();

  final timetableRepo = TimetableRepository();
  await timetableRepo.init();

  final settingsRepo = SettingsRepository();
  await settingsRepo.init();

  final attendanceRepo = AttendanceRepository();
  await attendanceRepo.init();

  // Initialize Services safely
  try {
    // Initialize Notifications
    await NotificationService.initializeNotification();

    // Initial rescheduling
    await timetableRepo.rescheduleAll();
    await timetableRepo.syncSubjectsWithAttendance();
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }

  // Initialize AI service
  final localMLService = LocalMLService();
  final localNLPService = LocalNlpService();
  final aiService = AIService(localMLService, localNLPService, settingsRepo);
  try {
    await aiService.init();
  } catch (e) {
    debugPrint('Error initializing AI service: $e');
  }

  // Train AI on existing data immediately
  try {
    aiService.trainModel(taskRepo.getAllTasks());
  } catch (e) {
    debugPrint('Error training AI: $e');
  }

  // Initialize Gamification service
  final gamificationService = GamificationService();
  await gamificationService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(taskRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        noteRepositoryProvider.overrideWithValue(noteRepo),
        timetableRepositoryProvider.overrideWithValue(timetableRepo),
        attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiServiceProvider.overrideWith((ref) => aiService),
        aiConfiguredProvider.overrideWith((ref) => aiService.isConfigured),
        gamificationServiceProvider.overrideWith((ref) => gamificationService),
      ],
      child: const TechMasterApp(),
    ),
  );
}

class TechMasterApp extends ConsumerWidget {
  const TechMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
