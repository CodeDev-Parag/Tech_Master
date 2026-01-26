class AppConstants {
  // App Info
  static const String appName = 'Tech Master';
  static const String appVersion = '1.1.4';

  // Hive Box Names
  static const String tasksBox = 'tasks_box';
  static const String categoriesBox = 'categories_box';
  static const String settingsBox = 'settings_box';
  static const String userStatsBox = 'user_stats_box';

  // Settings Keys
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';

  // Data Collection Backend URL (10.0.2.2 is localhost for Android Emulator)
  static const String dataCollectionServerUrl =
      'https://task-master-backend-qupx.onrender.com/collect';

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Personal', 'icon': 'user', 'color': 0xFF6366F1},
    {'name': 'Work', 'icon': 'briefcase', 'color': 0xFF3B82F6},
    {'name': 'Health', 'icon': 'heart', 'color': 0xFF22C55E},
    {'name': 'Shopping', 'icon': 'bag', 'color': 0xFFF59E0B},
    {'name': 'Learning', 'icon': 'book', 'color': 0xFF8B5CF6},
  ];

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
