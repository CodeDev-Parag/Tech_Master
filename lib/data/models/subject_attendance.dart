import 'package:hive/hive.dart';

part 'subject_attendance.g.dart';

@HiveType(typeId: 20)
class SubjectAttendance extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String subjectName;

  @HiveField(2)
  int attendedClasses;

  @HiveField(3)
  int totalClasses;

  @HiveField(4)
  double targetPercentage;

  @HiveField(5)
  DateTime lastUpdated;

  SubjectAttendance({
    required this.id,
    required this.subjectName,
    this.attendedClasses = 0,
    this.totalClasses = 0,
    this.targetPercentage = 75.0,
    required this.lastUpdated,
  });

  double get currentPercentage =>
      totalClasses == 0 ? 100.0 : (attendedClasses / totalClasses) * 100;

  bool get isSafe => currentPercentage >= targetPercentage;

  // Mass Bunk Calculator: How many classes can I skip?
  // (Attended) / (Total + x) >= Target
  // Attended >= Target * Total + Target * x
  // Attended - Target * Total >= Target * x
  // x <= (Attended - Target * Total) / Target
  // x = Floor((Attended / Target) - Total)
  int get classesCanBunk {
    if (totalClasses == 0) return 0;
    double target = targetPercentage / 100.0;
    int bunkable = ((attendedClasses / target) - totalClasses).floor();
    return bunkable > 0 ? bunkable : 0;
  }

  // Recovery Calculator: How many classes must I attend?
  // (Attended + x) / (Total + x) >= Target
  // Attended + x >= Target * Total + Target * x
  // x - Target * x >= Target * Total - Attended
  // x (1 - Target) >= Target * Total - Attended
  // x >= (Target * Total - Attended) / (1 - Target)
  int get classesMustAttend {
    double target = targetPercentage / 100.0;
    if (currentPercentage >= targetPercentage) return 0;

    int needed =
        ((target * totalClasses - attendedClasses) / (1 - target)).ceil();
    return needed > 0 ? needed : 0;
  }
}
