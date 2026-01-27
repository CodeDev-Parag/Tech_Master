import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import '../../data/models/timetable.dart';
import '../../data/repositories/attendance_repository.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotification() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback if timezone not found (e.g. emulator)
      tz.setLocalLocation(tz.local);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // Create a channel for attendance
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'attendance_channel', // id
      'Attendance Notifications', // title
      description: 'Notifications for upcoming classes', // description
      importance: Importance.max,
      playSound: true,
      enableLights: true,
      ledColor: Color(0xFF9D50BB),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(
      NotificationResponse notificationResponse) {
    onDidReceiveNotificationResponse(notificationResponse);
  }

  static Future<void> onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null && notificationResponse.actionId != null) {
      final subjectId = payload;
      final actionType = notificationResponse.actionId;

      final repo = AttendanceRepository();
      await repo.init();

      if (actionType == 'PRESENT') {
        await repo.markPresent(subjectId);
      } else if (actionType == 'ABSENT') {
        await repo.markAbsent(subjectId);
      }
    }
  }

  static Future<void> scheduleClassNotification(
      ClassSession session, String subjectId) async {
    // Calculate the next occurrence
    final now = tz.TZDateTime.now(tz.local);

    // session.dayOfWeek: 1 (Mon) - 7 (Sun)
    // now.weekday: 1 (Mon) - 7 (Sun)

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      session.startTimeHour,
      session.startTimeMinute,
    );

    // Adjust to the specific day of the week
    while (scheduledDate.weekday != session.dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the scheduled time is in the past, move to next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      session.id.hashCode,
      'Upcoming Class: ${session.subjectName}',
      'Time to mark your attendance!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'attendance_channel', 'Attendance Notifications',
            channelDescription: 'Notifications for upcoming classes',
            importance: Importance.max,
            priority: Priority.high,
            actions: [
              AndroidNotificationAction('PRESENT', 'Present',
                  titleColor: Colors.green),
              AndroidNotificationAction('ABSENT', 'Absent',
                  titleColor: Colors.red),
            ]),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: subjectId,
    );
  }

  static Future<void> cancelSessionNotification(String sessionId) async {
    await flutterLocalNotificationsPlugin.cancel(sessionId.hashCode);
  }
}
