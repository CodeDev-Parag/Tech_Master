import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_stats.dart';

class GamificationService extends StateNotifier<UserStats> {
  GamificationService() : super(UserStats());

  Box<UserStats>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<UserStats>(AppConstants.userStatsBox);
    state = _box?.get('stats') ?? UserStats();
  }

  Future<void> awardXp(int amount) async {
    int newXp = state.currentXp + amount;
    int newLevel = state.currentLevel;
    int tasksCompleted =
        state.tasksCompleted + 1; // Assuming usually called on completion

    // Level Up Logic
    // If we have enough XP for next level
    // Logic: Required for Next Level = Level * 100
    // If XP exceeds required, level up and reduce XP (or keep cumulative?)
    // Let's use cumulative for the level, but reset bar?
    // Usually: Level 1 (0-100), Level 2 (0-200).
    // Implementation:
    // while (newXp >= newLevel * 100)
    int required = newLevel * 100;
    while (newXp >= required) {
      newXp -= required;
      newLevel++;
      required = newLevel * 100;
      // Could trigger "Level Up" event here?
    }

    final newState = state.copyWith(
      currentLevel: newLevel,
      currentXp: newXp,
      tasksCompleted: tasksCompleted,
      lastActivityDate: DateTime.now(),
    );

    state = newState;
    await _box?.put('stats', newState);
  }

  // Simplified: +10 XP for task
  Future<void> completeTask() async {
    await awardXp(10);
  }
}
