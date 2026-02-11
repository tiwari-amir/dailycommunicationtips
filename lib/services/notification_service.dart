import 'package:daily_communication_tips/data/course_tasks.dart';
import 'package:daily_communication_tips/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'daily_reminders';
  static const String _channelName = 'Daily Reminders';
  static const String _channelDescription =
      'Reminders to complete daily communication tasks.';

  static const int _dailyReminderId = 1001;
  static const int _streakReminderId = 1002;
  static const String openTaskActionId = 'open_task';
  static const String markDoneActionId = 'mark_done';

  static const List<String> _encouragingBodies = [
    'Today\'s 2-minute communication tip is ready.',
    'A quick conversation boost is waiting for you.',
    'One small practice today, stronger conversations tomorrow.',
    'Take 2 minutes for today\'s communication task.',
    'Your daily tip is ready when you are.',
    'Keep your streak gentle and steady. Today\'s tip is live.',
    'Ready for today\'s mini communication challenge?',
    'A calm 2-minute task to sharpen your communication skills.',
    'Show up for today\'s tip. You\'re building real confidence.',
    'Today\'s task is open. Tap to continue your progress.',
  ];

  static void Function(NotificationResponse response)? _onNotificationResponse;

  static void setNotificationTapHandler(
    void Function(NotificationResponse response) handler,
  ) {
    _onNotificationResponse = handler;
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
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
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    await StorageService.resetDailyNotificationFlagsIfNeeded();
    final message = await _buildDailyMessage();
    final pinEnabled = await StorageService.getPinTodayTaskInPanel();

    await _plugin.cancel(_dailyReminderId);
    await _plugin.zonedSchedule(
      _dailyReminderId,
      message.title,
      message.body,
      _nextInstanceOfTime(time),
      _details(
        hasOpenAction: message.hasAction,
        hasMarkDoneAction: message.hasMarkDoneAction,
        pinned: pinEnabled,
        expandedText: message.expandedText,
        timeoutAfterMs: pinEnabled ? _timeoutUntilEndOfDay() : null,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: message.payload,
    );
  }

  static Future<void> syncPinnedNotificationState() async {
    await StorageService.resetDailyNotificationFlagsIfNeeded();
    final pinEnabled = await StorageService.getPinTodayTaskInPanel();
    if (!pinEnabled) return;

    final done = await StorageService.isTodayTaskDone();
    if (done) {
      await _plugin.cancel(_dailyReminderId);
      await scheduleDailyReminder(time: const TimeOfDay(hour: 8, minute: 0));
      return;
    }

    final message = await _buildDailyMessage();
    await _plugin.show(
      _dailyReminderId,
      message.title,
      message.body,
      _details(
        hasOpenAction: message.hasAction,
        hasMarkDoneAction: message.hasMarkDoneAction,
        pinned: true,
        expandedText: message.expandedText,
        timeoutAfterMs: _timeoutUntilEndOfDay(),
      ),
      payload: message.payload,
    );
  }

  static Future<void> handleMarkDoneAction() async {
    await StorageService.markTodayTaskDone();
    await _plugin.cancel(_dailyReminderId);
    await scheduleDailyReminder(time: const TimeOfDay(hour: 8, minute: 0));
  }

  static Future<void> scheduleStreakReminder({required TimeOfDay time}) async {
    await _plugin.cancel(_streakReminderId);
  }

  static Future<void> showTestDailyNow() async {
    final message = await _safeBuildDailyMessage();
    final pinEnabled = await StorageService.getPinTodayTaskInPanel();
    await _plugin.show(
      3001,
      message.title,
      message.body,
      _details(
        hasOpenAction: message.hasAction,
        hasMarkDoneAction: message.hasMarkDoneAction,
        pinned: pinEnabled,
        expandedText: message.expandedText,
      ),
      payload: message.payload,
    );
  }

  static Future<void> showTestStreakNow() async {
    await _plugin.show(
      3002,
      'Gentle streak check',
      'You can keep momentum with today\'s quick tip.',
      _details(
        hasOpenAction: false,
        hasMarkDoneAction: false,
        pinned: false,
        expandedText: 'Estimated time: 2 min',
      ),
    );
  }

  static Future<void> showStreakCongrats(int streak) async {
    if (streak <= 0) return;
    final title = 'Streak power!';
    final body = streak == 7
        ? 'Congratulations on your 7-day streak!'
        : 'Nice work! You are on a $streak-day streak.';
    await _plugin.show(
      2001,
      title,
      body,
      _details(
        hasOpenAction: false,
        hasMarkDoneAction: false,
        pinned: false,
        expandedText: body,
      ),
    );
  }

  static NotificationDetails _details({
    required bool hasOpenAction,
    required bool hasMarkDoneAction,
    required bool pinned,
    required String expandedText,
    int? timeoutAfterMs,
  }) {
    final actions = <AndroidNotificationAction>[
      if (hasOpenAction)
        const AndroidNotificationAction(
          openTaskActionId,
          'Start Today\'s Task',
          showsUserInterface: true,
        ),
      if (hasMarkDoneAction)
        const AndroidNotificationAction(
          markDoneActionId,
          'Mark as Done',
          showsUserInterface: true,
        ),
    ];

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(
          expandedText,
          contentTitle: 'Today\'s communication task',
          summaryText: 'Estimated time: 2 min',
        ),
        actions: actions.isEmpty ? null : actions,
        ongoing: pinned,
        autoCancel: !pinned,
        onlyAlertOnce: true,
        timeoutAfter: timeoutAfterMs,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<_DailyMessage> _buildDailyMessage() async {
    final nextTask = await _nextTaskForDeepLink();
    final done = await StorageService.isTodayTaskDone();
    final opened = await StorageService.isTodayTaskOpened();

    final taskTitle = 'Level ${nextTask.level} - Task ${nextTask.taskNumber}';
    final preview = _truncate(nextTask.content, max: 170);
    final expandedText = '$taskTitle\n$preview';
    final body = await _pickDailyBody(done: done, opened: opened);

    return _DailyMessage(
      title: 'Today\'s communication task',
      body: body,
      expandedText: expandedText,
      payload: 'task:${nextTask.level}:${nextTask.taskNumber}',
      hasAction: true,
      hasMarkDoneAction: opened && !done,
    );
  }

  static Future<_DailyMessage> _safeBuildDailyMessage() async {
    try {
      return await _buildDailyMessage();
    } catch (_) {
      return _DailyMessage(
        title: 'Today\'s communication task',
        body: '2 min practice for clearer conversations - Today 0/1',
        expandedText:
            'Level 1 - Task 1\nA short communication practice is ready.',
        payload: 'task:1:1',
        hasAction: true,
        hasMarkDoneAction: false,
      );
    }
  }

  static Future<DailyTask> _nextTaskForDeepLink() async {
    final completed = await StorageService.loadCompletedTaskIds();
    for (final task in allTasks) {
      final id = StorageService.taskId(task.level, task.taskNumber);
      if (!completed.contains(id)) {
        return task;
      }
    }
    return allTasks.last;
  }

  static Future<String> _pickDailyBody({
    required bool done,
    required bool opened,
  }) async {
    if (done) return 'Completed for today - calm progress, well done.';
    if (opened) return 'In progress - return when you are ready.';

    final streak = await StorageService.getStreak();
    final now = DateTime.now();
    final daySeed = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(now.year, 1, 1)).inDays;
    final index = (daySeed + (streak * 3)) % _encouragingBodies.length;
    final micro = _truncate(_encouragingBodies[index], max: 64);
    return '$micro - Today 0/1';
  }

  static String _truncate(String text, {int max = 120}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 3)}...';
  }

  static int _timeoutUntilEndOfDay() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final millis = end.difference(now).inMilliseconds;
    return millis < 1000 ? 1000 : millis;
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
  final String expandedText;
  final String payload;
  final bool hasAction;
  final bool hasMarkDoneAction;

  _DailyMessage({
    required this.title,
    required this.body,
    required this.expandedText,
    required this.payload,
    required this.hasAction,
    required this.hasMarkDoneAction,
  });
}
