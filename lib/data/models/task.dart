import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

@HiveType(typeId: 1)
enum TaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 2)
enum RecurrenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
}

@HiveType(typeId: 3)
class SubTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  int order;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.order,
  });

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? order,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }
}

@HiveType(typeId: 4)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  DateTime? reminderTime;

  @HiveField(5)
  Priority priority;

  @HiveField(6)
  TaskStatus status;

  @HiveField(7)
  String? categoryId;

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  List<SubTask> checklist;

  @HiveField(10)
  RecurrenceType recurrence;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.reminderTime,
    this.priority = Priority.medium,
    this.status = TaskStatus.pending,
    this.categoryId,
    List<String>? tags,
    List<SubTask>? checklist,
    this.recurrence = RecurrenceType.none,
    required this.createdAt,
    required this.updatedAt,
  })  : tags = tags ?? [],
        checklist = checklist ?? [];

  double get checklistProgress {
    if (checklist.isEmpty) return 1.0;
    final completed = checklist.where((s) => s.isCompleted).length;
    return completed / checklist.length;
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    Priority? priority,
    TaskStatus? status,
    String? categoryId,
    List<String>? tags,
    List<SubTask>? checklist,
    RecurrenceType? recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? List.from(this.tags),
      checklist: checklist ?? this.checklist.map((s) => s.copyWith()).toList(),
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
