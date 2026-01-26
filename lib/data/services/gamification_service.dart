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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newXp = state.currentXp + amount;
    int newLevel = state.currentLevel;
    int tasksCompleted = state.tasksCompleted + 1;
    int streakSteps = state.streakDays;

    // Streak Logic
    if (state.lastActivityDate == null) {
      streakSteps = 1;
    } else {
      final lastDate = DateTime(
        state.lastActivityDate!.year,
        state.lastActivityDate!.month,
        state.lastActivityDate!.day,
      );
      final diff = today.difference(lastDate).inDays;

      if (diff == 1) {
        streakSteps++;
      } else if (diff > 1) {
        streakSteps = 1;
      }
      // if diff == 0, keep current streak
    }

    // Level Up Logic
    int required = newLevel * 100;
    while (newXp >= required) {
      newXp -= required;
      newLevel++;
      required = newLevel * 100;
    }

    final newState = state.copyWith(
      currentLevel: newLevel,
      currentXp: newXp,
      tasksCompleted: tasksCompleted,
      streakDays: streakSteps,
      lastActivityDate: now,
    );

    state = newState;
    await _box?.put('stats', newState);
  }

  // Improved: +10 XP for task
  Future<void> completeTask() async {
    await awardXp(10);
  }
}
