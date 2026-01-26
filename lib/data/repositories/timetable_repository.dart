import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/timetable.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  throw UnimplementedError('Provider not initialized');
});

class TimetableRepository {
  static const String _boxName = 'timetable_box';
  Box<ClassSession>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(8)) {
      // Adapter will be generated
    }
    _box = await Hive.openBox<ClassSession>(_boxName);
  }

  List<ClassSession> getAllSessions() {
    return _box?.values.toList() ?? [];
  }

  List<ClassSession> getSessionsForDay(int dayOfWeek) {
    return _box?.values.where((s) => s.dayOfWeek == dayOfWeek).toList() ?? [];
  }

  // Sort sessions by time
  List<ClassSession> getSortedSessionsForDay(int dayOfWeek) {
    final sessions = getSessionsForDay(dayOfWeek);
    sessions.sort((a, b) {
      if (a.startTimeHour != b.startTimeHour) {
        return a.startTimeHour.compareTo(b.startTimeHour);
      }
      return a.startTimeMinute.compareTo(b.startTimeMinute);
    });
    return sessions;
  }

  Future<void> addSession(ClassSession session) async {
    await _box?.put(session.id, session);
  }

  Future<void> updateSession(ClassSession session) async {
    await _box?.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _box?.delete(id);
  }

  ClassSession? getNextClass() {
    final now = DateTime.now();
    final todaySessions = getSortedSessionsForDay(now.weekday);
    final nowMinutes = now.hour * 60 + now.minute;

    for (var session in todaySessions) {
      final sessionStartMinutes =
          session.startTimeHour * 60 + session.startTimeMinute;
      if (sessionStartMinutes > nowMinutes) {
        return session;
      }
    }

    // If no more classes today, check tomorrow
    // (Optional enhancement: look ahead to next day)
    return null;
  }
}
