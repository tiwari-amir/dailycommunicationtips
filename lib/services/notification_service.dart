import 'dart:math' as math;

import 'package:daily_communication_tips/data/course_tasks.dart';
import 'package:daily_communication_tips/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'daily_reminders';
  static const String _channelName = 'Daily Reminders';
  static const String _channelDescription =
      'Reminders to complete daily communication tasks.';

  static void Function(NotificationResponse response)? _onNotificationResponse;

  static void setNotificationTapHandler(
    void Function(NotificationResponse response) handler,
  ) {
    _onNotificationResponse = handler;
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final String timezone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationResponse?.call(response);
      },
    );
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
  }) async {
    final message = await _buildDailyMessage();
    await _plugin.zonedSchedule(
      1001,
      message.title,
      message.body,
      _nextInstanceOfTime(time),
      _details(hasOpenAction: message.hasAction),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: message.payload,
    );
  }

  static Future<void> scheduleStreakReminder({
    required TimeOfDay time,
  }) async {
    final streak = await StorageService.getStreak();
    if (streak < 1) {
      return;
    }
    final lastCompleted = await StorageService.getLastCompletedDate();
    if (lastCompleted == null) return;
    final hours = DateTime.now().difference(lastCompleted).inHours;
    if (hours < 48) {
      return;
    }
    const title = 'Keep your streak alive';
    const body = 'Hurry up - your streak is about to end.';
    await _plugin.zonedSchedule(
      1002,
      title,
      body,
      _nextInstanceOfTime(time),
      _details(hasOpenAction: false),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showTestDailyNow() async {
    final message = await _safeBuildDailyMessage();
    await _plugin.show(
      3001,
      message.title,
      message.body,
      _details(hasOpenAction: message.hasAction),
      payload: message.payload,
    );
  }

  static Future<void> showTestStreakNow() async {
    await _plugin.show(
      3002,
      'Keep your streak alive',
      'Hurry up - your streak is about to end.',
      _details(hasOpenAction: false),
    );
  }

  static Future<void> showStreakCongrats(int streak) async {
    if (streak <= 0) return;
    final title = 'Streak power!';
    final body = streak == 7
        ? 'Congratulations on your 7-day streak!'
        : 'Nice work! You are on a $streak-day streak.';
    await _plugin.show(2001, title, body, _details(hasOpenAction: false));
  }

  static NotificationDetails _details({required bool hasOpenAction}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        actions: hasOpenAction
            ? [
                const AndroidNotificationAction(
                  'open_task',
                  'Open Task',
                  showsUserInterface: true,
                )
              ]
            : null,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<_DailyMessage> _buildDailyMessage() async {
    final completed = await StorageService.loadCompletedTaskIds();
    DailyTask? nextTask;
    for (final task in allTasks) {
      final id = StorageService.taskId(task.level, task.taskNumber);
      if (!completed.contains(id)) {
        nextTask = task;
        break;
      }
    }

    if (nextTask == null) {
      final random = allTasks[math.Random().nextInt(allTasks.length)];
      return _DailyMessage(
        title: 'Daily tip',
        body: _truncate(random.content),
        payload: 'random',
        hasAction: false,
      );
    }

    return _DailyMessage(
      title: 'Today\'s tip - Level ${nextTask.level}, Task ${nextTask.taskNumber}',
      body: _truncate(nextTask.content),
      payload: 'task:${nextTask.level}:${nextTask.taskNumber}',
      hasAction: true,
    );
  }

  static Future<_DailyMessage> _safeBuildDailyMessage() async {
    try {
      return await _buildDailyMessage();
    } catch (_) {
      return _DailyMessage(
        title: 'Daily tip',
        body: 'Check in and complete today\'s task.',
        payload: 'random',
        hasAction: false,
      );
    }
  }

  static String _truncate(String text) {
    const max = 120;
    if (text.length <= max) return text;
    return '${text.substring(0, max - 1)}…';
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class _DailyMessage {
  final String title;
  final String body;
  final String payload;
  final bool hasAction;

  _DailyMessage({
    required this.title,
    required this.body,
    required this.payload,
    required this.hasAction,
  });
}

