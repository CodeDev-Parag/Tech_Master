import 'package:hive/hive.dart';

part 'user_stats.g.dart';

@HiveType(typeId: 3)
class UserStats {
  @HiveField(0)
  int currentLevel;

  @HiveField(1)
  int currentXp;

  @HiveField(2)
  int tasksCompleted;

  @HiveField(3)
  int streakDays;

  @HiveField(4)
  DateTime? lastActivityDate;

  UserStats({
    this.currentLevel = 1,
    this.currentXp = 0,
    this.tasksCompleted = 0,
    this.streakDays = 0,
    this.lastActivityDate,
  });

  // Level Logic: Level N requires N * 100 XP
  // Or cumulative: Level 2 needs 100, Level 3 needs 200 more (total 300)
  // Simple formula: Level N threshold = N * 100.
  int get xpToNextLevel => currentLevel * 100;

  double get progress => currentXp / xpToNextLevel;

  UserStats copyWith({
    int? currentLevel,
    int? currentXp,
    int? tasksCompleted,
    int? streakDays,
    DateTime? lastActivityDate,
  }) {
    return UserStats(
      currentLevel: currentLevel ?? this.currentLevel,
      currentXp: currentXp ?? this.currentXp,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      streakDays: streakDays ?? this.streakDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}
