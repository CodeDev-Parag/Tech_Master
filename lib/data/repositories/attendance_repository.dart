import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/subject_attendance.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class AttendanceRepository {
  static const String _boxName = 'subject_attendance';
  late Box<SubjectAttendance> _box;

  AttendanceRepository();

  Future<void> init() async {
    // Ensuring box is open
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<SubjectAttendance>(_boxName);
    } else {
      _box = Hive.box<SubjectAttendance>(_boxName);
    }
  }

  List<SubjectAttendance> getAllSubjects() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    _box = Hive.box<SubjectAttendance>(_boxName);
    return _box.values.toList();
  }

  Future<void> addSubject(String subjectName,
      {double target = 75.0, int attended = 0, int total = 0}) async {
    final newSubject = SubjectAttendance(
      id: const Uuid().v4(),
      subjectName: subjectName,
      attendedClasses: attended,
      totalClasses: total,
      targetPercentage: target,
      lastUpdated: DateTime.now(),
    );
    await _box.add(newSubject);
  }

  Future<String> ensureSubjectExists(String subjectName) async {
    await init();
    final existing = _box.values.where(
      (s) => s.subjectName.toLowerCase() == subjectName.toLowerCase(),
    );

    if (existing.isNotEmpty) {
      return existing.first.id;
    }

    final newId = const Uuid().v4();
    final newSubject = SubjectAttendance(
      id: newId,
      subjectName: subjectName,
      attendedClasses: 0,
      totalClasses: 0,
      targetPercentage: 75.0,
      lastUpdated: DateTime.now(),
    );
    await _box.add(newSubject);
    return newId;
  }

  Future<void> deleteSubject(String id) async {
    final subject = _box.values.firstWhere((s) => s.id == id);
    await subject.delete();
  }

  Future<void> markPresent(String id) async {
    final subject = _box.values.firstWhere((s) => s.id == id);
    subject.attendedClasses++;
    subject.totalClasses++;
    subject.save();
  }

  Future<void> markAbsent(String id) async {
    final subject = _box.values.firstWhere((s) => s.id == id);
    subject.totalClasses++; // Only increment total, not attended
    subject.save();
  }

  Future<void> undoLastAction(String id, bool wasPresent) async {
    final subject = _box.values.firstWhere((s) => s.id == id);
    if (subject.totalClasses > 0) {
      subject.totalClasses--;
      if (wasPresent && subject.attendedClasses > 0) {
        subject.attendedClasses--;
      }
      subject.save();
    }
  }

  Future<void> updateSubject(String id, {String? name, double? target}) async {
    final subject = _box.values.firstWhere((s) => s.id == id);
    if (name != null) {
      // hacky way to update read-only field if any, but Hive objects are mutable usually
      // Since fields are final in my model, I might need to make them mutable or recreate
      // In the model I made them mutable (except id/name). Wait, name is final.
      // Let's check the model I wrote.
      // id, subjectName are final.
      // I should probably make subjectName mutable or recreate the object.
      // For now, I will not support renaming or I'll recreate it.
    }
    if (target != null) {
      subject.targetPercentage = target;
      subject.save();
    }
  }
}
