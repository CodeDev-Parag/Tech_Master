import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../../data/models/timetable.dart';
import '../../data/repositories/attendance_repository.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: 'attendance_channel_group',
          channelKey: 'attendance_channel',
          channelName: 'Attendance Notifications',
          channelDescription: 'Notifications for upcoming classes',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'attendance_channel_group',
          channelGroupName: 'Attendance group',
        )
      ],
      debug: true,
    );

    // Get permission
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.channelKey == 'attendance_channel') {
      final String? subjectId = receivedAction.payload?['subjectId'];
      final String? actionType = receivedAction.buttonKeyPressed;

      if (subjectId != null) {
        final repo = AttendanceRepository();
        await repo.init(); // Ensure Hive is ready

        if (actionType == 'PRESENT') {
          await repo.markPresent(subjectId);
        } else if (actionType == 'ABSENT') {
          await repo.markAbsent(subjectId);
        }
      }
    }
  }

  static Future<void> scheduleClassNotification(
      ClassSession session, String subjectId) async {
    // Calculate next occurrence
    // final now = DateTime.now();
    // DateTime scheduleDay = DateTime(now.year, now.month, now.day,
    //     session.startTimeHour, session.startTimeMinute);

    // If it's earlier today or a different day, we need to adjust to the next occurrence
    // But since `awesome_notifications` handles weekly schedules, we can just use the day of week.

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: session.id.hashCode,
        channelKey: 'attendance_channel',
        title: 'Upcoming Class: ${session.subjectName}',
        body: 'Time to mark your attendance!',
        payload: {'subjectId': subjectId},
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'PRESENT',
          label: 'Present',
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'ABSENT',
          label: 'Absent',
          color: Colors.red,
        ),
      ],
      schedule: NotificationCalendar(
        weekday: session.dayOfWeek,
        hour: session.startTimeHour,
        minute: session.startTimeMinute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelSessionNotification(String sessionId) async {
    await AwesomeNotifications().cancel(sessionId.hashCode);
  }
}
