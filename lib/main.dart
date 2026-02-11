import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:daily_communication_tips/screens/reading_screen.dart';
import 'package:daily_communication_tips/data/course_tasks.dart';
import 'package:daily_communication_tips/screens/level_tasks_screen.dart';
import 'services/gamification_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'widgets/segmented_circular_progress.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await StorageService.resetDailyNotificationFlagsIfNeeded();
  NotificationService.setNotificationTapHandler(_handleNotificationResponse);
  await NotificationService.scheduleDailyReminder(
    time: const TimeOfDay(hour: 8, minute: 0),
  );
  await NotificationService.syncPinnedNotificationState();
  runApp(CommHelperApp());
}

void _handleNotificationResponse(NotificationResponse response) {
  if (response.actionId == NotificationService.markDoneActionId) {
    NotificationService.handleMarkDoneAction();
    return;
  }

  final payload = response.payload;
  if (payload == null) return;
  if (payload.startsWith('task:')) {
    final parts = payload.split(':');
    if (parts.length == 3) {
      final level = int.tryParse(parts[1]);
      final taskNumber = int.tryParse(parts[2]);
      if (level != null && taskNumber != null) {
        StorageService.markTodayTaskOpened();
        NotificationService.syncPinnedNotificationState();
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ReadingScreen(
              currentLevel: level,
              currentTaskNumber: taskNumber,
            ),
          ),
        );
      }
    }
  }
}

class CommHelperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Daily Communication Helper',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgBase,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentPrimary,
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int currentLevel = 1;
  int currentTaskNumber = 1;
  int streak = 0;
  int bestStreak = 0;
  bool pinTodayTaskInPanel = false;
  Set<String> completedTaskIds = {};
  Set<String> completedDates = {};
  bool unlockAllLevels = false;
  int currentXP = 0;
  Map<String, int> _taskXpMap = {};
  late final AnimationController _pulseController;
  int freezeCount = 0;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _initTimeZone();
    _initializeXpMap();
    _loadStreak();
    _loadBestStreak();
    _loadFreezes();
    _loadPinSetting();
    _loadCompletedTasks();
    _loadUnlockAll();
  }

  Future<void> _initTimeZone() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to default/UTC if local timezone fails
    }
    _scheduleStreakExpiryNotifications();
  }

  void _initializeXpMap() {
    int count1_5 = 0;
    int count6_10 = 0;
    int count11_15 = 0;
    int count16_20 = 0;

    for (var t in allTasks) {
      if (t.level <= 5) count1_5++;
      else if (t.level <= 10) count6_10++;
      else if (t.level <= 15) count11_15++;
      else if (t.level <= 20) count16_20++;
    }

    double xp1_5 = count1_5 > 0 ? 40000 / count1_5 : 0;
    double xp6_10 = count6_10 > 0 ? 30000 / count6_10 : 0;
    double xp11_15 = count11_15 > 0 ? 20000 / count11_15 : 0;
    double xp16_20 = count16_20 > 0 ? 10000 / count16_20 : 0;

    _taskXpMap.clear();
    for (var t in allTasks) {
      String id = StorageService.taskId(t.level, t.taskNumber);
      int xp = 0;
      if (t.level <= 5) xp = xp1_5.round();
      else if (t.level <= 10) xp = xp6_10.round();
      else if (t.level <= 15) xp = xp11_15.round();
      else if (t.level <= 20) xp = xp16_20.round();
      _taskXpMap[id] = xp;
    }
  }

  Future<void> _loadStreak() async {
    int s = await StorageService.getStreak();
    setState(() => streak = s);
  }

  Future<void> _loadBestStreak() async {
    final value = await StorageService.getBestStreak();
    if (!mounted) return;
    setState(() => bestStreak = value);
  }

  Future<void> _loadFreezes() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('freeze_count')) {
      await prefs.setInt('freeze_count', 3);
    }
    setState(() {
      freezeCount = prefs.getInt('freeze_count') ?? 3;
    });
  }

  Future<void> _loadPinSetting() async {
    final value = await StorageService.getPinTodayTaskInPanel();
    if (!mounted) return;
    setState(() => pinTodayTaskInPanel = value);
  }

  Future<void> _loadCompletedTasks() async {
    final ids = await StorageService.loadCompletedTaskIds();
    final dates = await StorageService.loadCompletedDates();
    final nextActive = _findNextIncompleteTaskFromIds(ids);
    
    int xp = 0;
    for (var id in ids) {
      xp += _taskXpMap[id] ?? 0;
    }

    setState(() {
      completedTaskIds = ids;
      completedDates = dates;
      currentXP = xp;
      if (nextActive != null) {
        currentLevel = nextActive.level;
        currentTaskNumber = nextActive.taskNumber;
      }
    });
  }

  Future<void> _loadUnlockAll() async {
    final value = await StorageService.getUnlockAll();
    if (!mounted) return;
    setState(() => unlockAllLevels = value);
    if (value) {
      await _markAllTasksCompleted();
    }
  }

  Future<void> _scheduleStreakExpiryNotifications() async {
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Cancel existing streak notifications first
    await _notificationsPlugin.cancel(1001);
    await _notificationsPlugin.cancel(1002);
    await _notificationsPlugin.cancel(1003);
    await _notificationsPlugin.cancel(1004);

    if (completedDates.contains(todayKey)) return;

    final androidDetails = const AndroidNotificationDetails(
      'streak_expiry_channel',
      'Streak Expiry',
      channelDescription: 'Notifications for expiring streaks',
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    void schedule(int hour, int id, String title, String body) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
      );
      if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    if (streak > 0) {
      schedule(12, 1001, 'Keep the streak alive! 🔥', '12 hours left to complete today\'s task.');
      schedule(18, 1002, 'Don\'t lose your progress! ⏳', '6 hours remaining to save your $streak-day streak.');
      schedule(21, 1003, 'Streak expiring soon! ⚠️', '3 hours left! Take 2 minutes to complete your task.');
      schedule(23, 1004, 'Last chance! 🚨', '1 hour left to save your streak!');
    } else {
      schedule(12, 1001, 'Start your journey 🚀', 'Start your productive journey. Follow a task today.');
      schedule(18, 1002, 'Time for growth 🌱', 'Take a moment for yourself. Start your streak today.');
    }
  }

  void _startTask() {
    final nextActive = _findNextIncompleteTask();
    final startLevel = nextActive?.level ?? currentLevel;
    final startTaskNumber = nextActive?.taskNumber ?? currentTaskNumber;
    StorageService.markTodayTaskOpened();
    NotificationService.syncPinnedNotificationState();
    _openTask(startLevel, startTaskNumber);
  }

  void _openTask(
    int level,
    int taskNumber, {
    bool openedFromCompletedTask = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          currentLevel: level,
          currentTaskNumber: taskNumber,
          onTaskComplete: _advanceTask,
          openedFromCompletedTask: openedFromCompletedTask,
        ),
      ),
    ).then((_) {
      _loadStreak();
      _loadBestStreak();
      _loadCompletedTasks();
      _loadFreezes();
    });
  }

  void _advanceTask(int level, int taskNumber) {
    setState(() {
      currentLevel = level;
      currentTaskNumber = taskNumber;
    });
    _loadStreak(); // Refresh streak after task completion
    _loadBestStreak();
    _loadCompletedTasks();
  }

  Future<void> _resetAllProgress() async {
    await StorageService.resetAllProgress();
    final preservedStreak = await StorageService.getStreak();
    final preservedBestStreak = await StorageService.getBestStreak();
    setState(() {
      currentLevel = 1;
      currentTaskNumber = 1;
      streak = preservedStreak;
      bestStreak = preservedBestStreak;
      pinTodayTaskInPanel = false;
      completedTaskIds = {};
      completedDates = {};
      unlockAllLevels = false;
      currentXP = 0;
      freezeCount = 3;
    });
  }

  Future<void> _unlockAllLevels() async {
    await StorageService.setUnlockAll(true);
    await _markAllTasksCompleted();
    if (!mounted) return;
    setState(() => unlockAllLevels = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Max level reached. All levels unlocked.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPathSections(_TaskRef? nextActive, int nextActiveIndex) {
    const groups = [
      _PathGroup(
        title: 'Foundation',
        subtitle: 'Levels 1-5',
        minLevel: 1,
        maxLevel: 5,
      ),
      _PathGroup(
        title: 'Practice',
        subtitle: 'Levels 6-10',
        minLevel: 6,
        maxLevel: 10,
      ),
      _PathGroup(
        title: 'Application',
        subtitle: 'Levels 11-15',
        minLevel: 11,
        maxLevel: 15,
      ),
      _PathGroup(
        title: 'Mastery',
        subtitle: 'Levels 16-20',
        minLevel: 16,
        maxLevel: 20,
      ),
    ];

    return Column(
      children: [
        for (final group in groups) ...[
          _buildPathGroupTile(group, nextActive, nextActiveIndex),
          if (group != groups.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPathGroupTile(
    _PathGroup group,
    _TaskRef? nextActive,
    int nextActiveIndex,
  ) {
    final sectionTasks = allTasks
        .where((t) => t.level >= group.minLevel && t.level <= group.maxLevel)
        .toList();
    final doneCount = sectionTasks
        .where((t) => completedTaskIds.contains(StorageService.taskId(t.level, t.taskNumber)))
        .length;
    final hasActiveInSection =
        nextActive != null &&
        nextActive.level >= group.minLevel &&
        nextActive.level <= group.maxLevel;
    final activeId = nextActive == null
        ? null
        : StorageService.taskId(nextActive.level, nextActive.taskNumber);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressTrack),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: hasActiveInSection,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(
                text: '$doneCount/${sectionTasks.length}',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          subtitle: Text(
            group.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            for (final task in sectionTasks)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildPathTaskRow(task, activeId, nextActiveIndex),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathTaskRow(
    DailyTask task,
    String? activeId,
    int nextActiveIndex,
  ) {
    final globalIndex = allTasks.indexWhere(
      (t) => t.level == task.level && t.taskNumber == task.taskNumber,
    );
    final id = StorageService.taskId(task.level, task.taskNumber);
    final isDone = completedTaskIds.contains(id);
    final isActive = activeId == id;
    final isLocked =
        !unlockAllLevels &&
        !isDone &&
        !isActive &&
        nextActiveIndex >= 0 &&
        globalIndex > nextActiveIndex;

    return Opacity(
      opacity: isLocked ? 0.65 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLocked
            ? null
            : () => _openTask(
                  task.level,
                  task.taskNumber,
                  openedFromCompletedTask: isDone,
                ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.accentSecondary : AppColors.progressTrack,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 17,
                color: isDone
                    ? AppColors.progressGood
                    : isActive
                    ? AppColors.accentSecondary
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'L${task.level} - T${task.taskNumber}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isDone)
                          const _StatusPill(
                            text: 'Completed',
                            color: AppColors.progressGood,
                          )
                        else if (isActive)
                          const _StatusPill(
                            text: 'Active',
                            color: AppColors.accentSecondary,
                          )
                        else if (isLocked)
                          const _StatusPill(
                            text: 'Locked',
                            color: AppColors.textTertiary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllTasksCompleted() async {
    final ids = allTasks
        .map((t) => StorageService.taskId(t.level, t.taskNumber))
        .toSet();
    await StorageService.setCompletedTaskIds(ids);
    if (!mounted) return;
    setState(() {
      completedTaskIds = ids;
      currentLevel = 20;
      currentTaskNumber = _getTotalTasksForLevel(20);
    });
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool localPinSetting = pinTodayTaskInPanel;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_open_rounded),
                      title: const Text('Unlock All Levels'),
                      subtitle: const Text(
                        'Access any level without completing tasks',
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _unlockAllLevels();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        localPinSetting
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                      ),
                      title: const Text(
                        'Pin today\'s task in notification panel',
                      ),
                      subtitle: const Text(
                        'Keep it visible until done or day ends',
                      ),
                      trailing: Switch(
                        value: localPinSetting,
                        onChanged: (value) async {
                          setModalState(() => localPinSetting = value);
                          if (mounted) {
                            setState(() => pinTodayTaskInPanel = value);
                          }
                          await StorageService.setPinTodayTaskInPanel(value);
                          await NotificationService.syncPinnedNotificationState();
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh_rounded),
                      title: const Text('Reset All Progress'),
                      subtitle: const Text(
                        'Factory reset: streaks, progress, and unlocks',
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _resetAllProgress();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('About'),
                      subtitle: const Text(
                        'A personal note from the developer',
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('About'),
                            content: const Text(
                              'The developer built this app for themselves to use.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _getTotalTasksForLevel(int level) {
    try {
      return allTasks.firstWhere((t) => t.level == level).totalTasks;
    } catch (e) {
      return 1;
    }
  }

  LinearGradient _levelBadgeGradient(int level) {
    double tierProgress;
    Color start;
    Color end;
    if (level <= 3) {
      tierProgress = (level - 1) / 2;
      start = const Color(0xFF9D50FF);
      end = const Color(0xFF5CE1E6);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFFB36BFF), tierProgress)!,
          Color.lerp(end, const Color(0xFF7CF7FF), tierProgress)!,
        ],
      );
    } else if (level <= 6) {
      tierProgress = (level - 4) / 2;
      start = const Color(0xFF43C6AC);
      end = const Color(0xFF191654);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFF6FFFCF), tierProgress)!,
          Color.lerp(end, const Color(0xFF3A2B86), tierProgress)!,
        ],
      );
    } else if (level <= 9) {
      tierProgress = (level - 7) / 2;
      start = const Color(0xFF00C6FF);
      end = const Color(0xFF0072FF);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFF5EDBFF), tierProgress)!,
          Color.lerp(end, const Color(0xFF0B4BFF), tierProgress)!,
        ],
      );
    } else if (level <= 12) {
      tierProgress = (level - 10) / 2;
      start = const Color(0xFF8E2DE2);
      end = const Color(0xFF4A00E0);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFFB06BFF), tierProgress)!,
          Color.lerp(end, const Color(0xFF6F3BFF), tierProgress)!,
        ],
      );
    } else if (level <= 15) {
      tierProgress = (level - 13) / 2;
      start = const Color(0xFFFF512F);
      end = const Color(0xFFDD2476);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFFFF7A5A), tierProgress)!,
          Color.lerp(end, const Color(0xFFE04FA0), tierProgress)!,
        ],
      );
    } else if (level <= 18) {
      tierProgress = (level - 16) / 2;
      start = const Color(0xFFFF6A00);
      end = const Color(0xFFEE0979);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFFFF8C42), tierProgress)!,
          Color.lerp(end, const Color(0xFFFF4FA3), tierProgress)!,
        ],
      );
    } else {
      tierProgress = (level - 19) / 1;
      start = const Color(0xFFFFD200);
      end = const Color(0xFFFF6F00);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(start, const Color(0xFFFFE27A), tierProgress)!,
          Color.lerp(end, const Color(0xFFFF9B3D), tierProgress)!,
        ],
      );
    }
  }

  _TaskRef? _findNextIncompleteTask() {
    for (final task in allTasks) {
      final id = StorageService.taskId(task.level, task.taskNumber);
      if (!completedTaskIds.contains(id)) {
        return _TaskRef(task.level, task.taskNumber);
      }
    }
    return null;
  }

  _TaskRef? _findNextIncompleteTaskFromIds(Set<String> ids) {
    for (final task in allTasks) {
      final id = StorageService.taskId(task.level, task.taskNumber);
      if (!ids.contains(id)) {
        return _TaskRef(task.level, task.taskNumber);
      }
    }
    return null;
  }

  Widget _buildLevelBadge(int displayLevel) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.98 + (_pulseController.value * 0.04);
        return Transform.scale(
          scale: pulse,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 2),
              SizedBox(
                height: 58,
                width: 58,
                child: LevelBadgeSprite(level: displayLevel, size: 58),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlockAllLevels
                        ? 'Level $displayLevel'
                        : 'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Current badge',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.15,
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFireStreak() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressTrack),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF5F6D),
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$streak',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          const Icon(
            Icons.ac_unit_rounded,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$freezeCount',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRing(int percent, String label, int sectionCount) {
    final ringSize = sectionCount <= 2
        ? 42.0
        : sectionCount == 3
        ? 36.0
        : 32.0;
    final fontSize = sectionCount <= 2
        ? 11.0
        : sectionCount == 3
        ? 10.0
        : 9.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.12),
                  ),
                ),
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentSecondary,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(
    double progress, {
    required String primaryText,
    required String secondaryText,
    required bool todayCompleted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: todayCompleted
              ? AppColors.progressGood.withOpacity(0.42)
              : AppColors.progressTrack.withOpacity(0.35),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: todayCompleted
                ? AppColors.progressGood.withOpacity(0.12)
                : AppColors.accentSecondary.withOpacity(0.08),
            blurRadius: todayCompleted ? 16 : 10,
          ),
        ],
      ),
      child: SegmentedCircularProgress(
        progress: progress,
        size: 150,
        strokeWidth: 12,
        segments: 4,
        gapDegrees: 4,
        gradientColors: const [
          AppColors.accentSecondary,
          AppColors.accentFocus,
          Color(0xFF8C6FFF),
        ],
        trackColor: AppColors.progressTrack.withOpacity(0.35),
        glowColor: AppColors.accentSecondary,
        center: Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bgCard,
                AppColors.bgElevated.withOpacity(0.85),
              ],
            ),
            border: Border.all(color: AppColors.progressTrack),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  todayCompleted
                      ? Icons.verified_rounded
                      : Icons.trending_up_rounded,
                  size: 16,
                  color: todayCompleted
                      ? AppColors.progressGood
                      : AppColors.accentSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  primaryText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  secondaryText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCalendarDialog() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingEmpty = (firstDay.weekday % 7); // 0=Sun

    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('This Month'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _WeekdayLabel('S'),
                    _WeekdayLabel('M'),
                    _WeekdayLabel('T'),
                    _WeekdayLabel('W'),
                    _WeekdayLabel('T'),
                    _WeekdayLabel('F'),
                    _WeekdayLabel('S'),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(rows, (row) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (col) {
                        final index = row * 7 + col;
                        final dayNum = index - leadingEmpty + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const _DayCell.empty();
                        }
                        final dayKey =
                            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                        final isDone = completedDates.contains(dayKey);
                        return _DayCell(day: dayNum, isDone: isDone);
                      }),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communicationTotal = allTasks.length;
    final communicationCompleted = completedTaskIds.length;
    final totalTasks = communicationTotal;
    final totalCompleted = communicationCompleted;
    final overallProgress = unlockAllLevels || totalTasks == 0
        ? 1.0
        : (totalCompleted / totalTasks).clamp(0.0, 1.0);
    final overallPercent = (overallProgress * 100).round();
    final nextActive = _findNextIncompleteTask();
    final nextActiveIndex = nextActive == null
        ? -1
        : allTasks.indexWhere(
            (t) =>
                t.level == nextActive.level &&
                t.taskNumber == nextActive.taskNumber,
          );
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 370 ? 18.0 : 24.0;
    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayCompleted = completedDates.contains(todayKey);
    final taskForCard = allTasks.firstWhere(
      (t) =>
          t.level == (nextActive?.level ?? currentLevel) &&
          t.taskNumber == (nextActive?.taskNumber ?? currentTaskNumber),
      orElse: () => allTasks.first,
    );
    final taskPreview = taskForCard.content.length > 110
        ? '${taskForCard.content.substring(0, 110)}...'
        : taskForCard.content;
    final motivation = todayCompleted
        ? 'Nice consistency. See you tomorrow for the next step.'
        : streak >= 7
        ? 'You are on a ${streak}-day run. Keep the streak alive today.'
        : 'Tiny daily practice builds confident conversations.';
    final gatedLevel = unlockAllLevels
        ? currentLevel
        : math.min(currentLevel, 19);
    final currentBadgeName = GamificationService.currentBadgeName(gatedLevel);
    final unlockedBadges = GamificationService.unlockedBadgeCount(gatedLevel);
    final nextBadgeLevel = GamificationService.nextBadgeMilestone(gatedLevel);
    final nextBadgeName = GamificationService.nextBadgeName(gatedLevel);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgBase, AppColors.bgElevated],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: LevelBadgeSprite(level: gatedLevel, size: 50),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Level $gatedLevel',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${currentXP.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} XP',
                              style: TextStyle(
                                color: AppColors.accentSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildFireStreak(),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _showCalendarDialog,
                            tooltip: 'Monthly progress',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _showSettingsSheet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Image.asset(
                    'assets/images/title.png',
                    height: 62,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: overallProgress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return _buildProgressRing(
                        value,
                        primaryText: '$overallPercent%',
                        secondaryText: 'Overall',
                        todayCompleted: todayCompleted,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Course progress: $overallPercent%',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.progressTrack),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              todayCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 16,
                              color: todayCompleted
                                  ? AppColors.progressGood
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                todayCompleted
                                    ? 'Daily win recorded'
                                    : 'Complete today for a daily win',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.progressTrack),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 16,
                              color: AppColors.accentSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nextBadgeLevel == null
                                    ? 'All badge tiers unlocked'
                                    : 'Next reward at Lv $nextBadgeLevel',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.progressTrack),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 18,
                        color: AppColors.accentSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nextBadgeLevel == null
                              ? 'Badge: $currentBadgeName ($unlockedBadges/${GamificationService.milestoneLevels.length})'
                              : 'Badge: $currentBadgeName - Next at Level $nextBadgeLevel ($nextBadgeName)',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPrimary, AppColors.accentFocus],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.progressTrack),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Level ${nextActive?.level ?? currentLevel} - Task ${nextActive?.taskNumber ?? currentTaskNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          taskPreview,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: todayCompleted ? null : _startTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPrimary,
                              foregroundColor: AppColors.textPrimary,
                              disabledBackgroundColor: Colors.white24,
                              disabledForegroundColor: AppColors.textSecondary,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              todayCompleted
                                  ? 'Completed for today'
                                  : 'Follow today\'s task',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.progressTrack),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Path',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete in order. Revisit any completed task anytime.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPathSections(nextActive, nextActiveIndex),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    motivation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskRef {
  final int level;
  final int taskNumber;

  _TaskRef(this.level, this.taskNumber);
}

class _PathGroup {
  final String title;
  final String subtitle;
  final int minLevel;
  final int maxLevel;

  const _PathGroup({
    required this.title,
    required this.subtitle,
    required this.minLevel,
    required this.maxLevel,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SectionsScreen extends StatefulWidget {
  final int initialIndex;
  final int gatedLevel;
  final bool unlockAllLevels;
  final void Function(int newLevel, int newTaskNumber)? onTaskComplete;

  const SectionsScreen({
    super.key,
    required this.initialIndex,
    required this.gatedLevel,
    required this.unlockAllLevels,
    required this.onTaskComplete,
  });

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index > 1) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _index == 0 ? 'Communication tips' : 'Small talk expert',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _goTo(_index - 1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => _goTo(_index + 1),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgBase, AppColors.bgElevated],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Image.asset(
                  'assets/images/title.png',
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: [
                    _CommunicationLevels(
                      gatedLevel: widget.gatedLevel,
                      unlockAllLevels: widget.unlockAllLevels,
                      onTaskComplete: widget.onTaskComplete,
                    ),
                    const _SmallTalkPlaceholder(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunicationLevels extends StatelessWidget {
  final int gatedLevel;
  final bool unlockAllLevels;
  final void Function(int newLevel, int newTaskNumber)? onTaskComplete;

  const _CommunicationLevels({
    required this.gatedLevel,
    required this.unlockAllLevels,
    required this.onTaskComplete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridCrossAxis = screenWidth < 360 ? 3 : 4;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCrossAxis,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          final levelIndex = index + 1;
          final isLocked = !unlockAllLevels && levelIndex > gatedLevel;
          final isCompleted = levelIndex < gatedLevel;
          final isCurrent = levelIndex == gatedLevel;

          return GestureDetector(
            onTap: () {
              if (!isLocked) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelTasksScreen(
                      level: levelIndex,
                      onTaskComplete: onTaskComplete,
                    ),
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isLocked ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(16),
                border: isCurrent
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '$levelIndex',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isLocked
                            ? Colors.white.withOpacity(0.35)
                            : Colors.white,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 18,
                      ),
                    ),
                  if (isLocked)
                    Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SmallTalkPlaceholder extends StatelessWidget {
  const _SmallTalkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Small talk content coming soon.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LevelBadgeSprite extends StatelessWidget {
  final int level;
  final double size;
  final bool locked;
  final bool dim;

  const LevelBadgeSprite({
    super.key,
    required this.level,
    required this.size,
    this.locked = false,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final levelIndex = level.clamp(1, 20);
    final fileName = 'level$levelIndex.png';
    Widget image = Image.asset(
      'assets/badges/$fileName',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (locked) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.45, child: image),
      );
    } else if (dim) {
      image = Opacity(opacity: 0.85, child: image);
    }

    return SizedBox(width: size, height: size, child: image);
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int? day;
  final bool isDone;
  const _DayCell({this.day, this.isDone = false});
  const _DayCell.empty({super.key}) : day = null, isDone = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: day == null
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.accentPrimary.withOpacity(0.8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone ? AppColors.accentPrimary : Colors.black12,
                ),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDone ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
    );
  }
}
