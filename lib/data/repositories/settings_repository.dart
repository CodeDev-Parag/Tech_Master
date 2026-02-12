import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  static const String boxName = 'settings_box';

  // Keys
  static const String keyContinuousLearning = 'continuous_learning';
  static const String keyAiMode = 'ai_mode'; // 'local' or 'online'
  static const String keyDarkMode = 'dark_mode';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  // Continuous Learning
  bool get continuousLearningEnabled =>
      _box.get(keyContinuousLearning, defaultValue: false);
  Future<void> setContinuousLearning(bool enabled) async {
    await _box.put(keyContinuousLearning, enabled);
  }

  // AI Mode (True = Local, False = Online/RuleBased)
  // Defaulting to True (Local) since user downloaded the model
  bool get isLocalLlmMode => _box.get(keyAiMode, defaultValue: true);
  Future<void> setLocalLlmMode(bool isLocal) async {
    await _box.put(keyAiMode, isLocal);
  }

  // Custom Server Settings
  static const String keyServerIp = 'server_ip';
  static const String keyUseCustomServer = 'use_custom_server';

  // Default to localhost for emulator (10.0.2.2) or typical PC IP
  String get serverIp => _box.get(keyServerIp, defaultValue: '192.168.1.10');
  Future<void> setServerIp(String ip) async {
    await _box.put(keyServerIp, ip);
  }

  bool get useCustomServer => _box.get(keyUseCustomServer, defaultValue: false);
  Future<void> setUseCustomServer(bool enabled) async {
    await _box.put(keyUseCustomServer, enabled);
  }

  // Pro Mode
  static const String keyProMode = 'pro_mode';
  bool get isProMode => _box.get(keyProMode, defaultValue: false);
  Future<void> setProMode(bool enabled) async {
    await _box.put(keyProMode, enabled);
  }

  // College Mode
  static const String keyCollegeMode = 'college_mode';
  bool get isCollegeMode => _box.get(keyCollegeMode, defaultValue: false);
  Future<void> setCollegeMode(bool enabled) async {
    await _box.put(keyCollegeMode, enabled);
  }
  // What's New Card
  static const String keyShowWhatsNew = 'show_whats_new_2_1_5';
  bool get showWhatsNew => _box.get(keyShowWhatsNew, defaultValue: true);
  Future<void> setShowWhatsNew(bool show) async {
    await _box.put(keyShowWhatsNew, show);
  }
}
