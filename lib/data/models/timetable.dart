import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'timetable.g.dart';

@HiveType(typeId: 8)
class ClassSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectName;

  @HiveField(2)
  final String? professorName;

  @HiveField(3)
  final String? roomNumber;

  @HiveField(4)
  final int startTimeHour;

  @HiveField(5)
  final int startTimeMinute;

  @HiveField(6)
  final int endTimeHour;

  @HiveField(7)
  final int endTimeMinute;

  @HiveField(8)
  final int dayOfWeek; // 1 = Monday, 7 = Sunday (matching DateTime.weekday)

  @HiveField(9)
  final int colorValue;

  ClassSession({
    required this.id,
    required this.subjectName,
    this.professorName,
    this.roomNumber,
    required this.startTimeHour,
    required this.startTimeMinute,
    required this.endTimeHour,
    required this.endTimeMinute,
    required this.dayOfWeek,
    required this.colorValue,
  });

  TimeOfDay get startTime =>
      TimeOfDay(hour: startTimeHour, minute: startTimeMinute);

  TimeOfDay get endTime => TimeOfDay(hour: endTimeHour, minute: endTimeMinute);

  Color get color => Color(colorValue);
}
