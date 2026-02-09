import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:daily_communication_tips/screens/reading_screen.dart';
import 'package:daily_communication_tips/data/course_tasks.dart';
import 'package:daily_communication_tips/screens/level_tasks_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

const Color kAccentPrimary = Color(0xFF5F67FF);
const Color kAccentSecondary = Color(0xFF8AE8FF);
const Color kAccentTertiary = Color(0xFFB8FFF2);
const Color kDeepBlue = Color(0xFF4F6EEB);
const Color kDeepPurple = Color(0xFF6D3EF3);

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  NotificationService.setNotificationTapHandler(_handleNotificationResponse);
  await NotificationService.scheduleDailyReminder(
    time: const TimeOfDay(hour: 7, minute: 0),
  );
  await NotificationService.scheduleStreakReminder(
    time: const TimeOfDay(hour: 21, minute: 0),
  );
  runApp(CommHelperApp());
}

void _handleNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null) return;
  if (payload.startsWith('task:')) {
    final parts = payload.split(':');
    if (parts.length == 3) {
      final level = int.tryParse(parts[1]);
      final taskNumber = int.tryParse(parts[2]);
      if (level != null && taskNumber != null) {
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
        primarySwatch: Colors.blue,
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int currentLevel = 1;
  int currentTaskNumber = 1;
  int streak = 0;
  Set<String> completedTaskIds = {};
  Set<String> completedDates = {};
  bool unlockAllLevels = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _loadStreak();
    _loadCompletedTasks();
    _loadUnlockAll();
  }

  Future<void> _loadStreak() async {
    int s = await StorageService.getStreak();
    setState(() => streak = s);
  }

  Future<void> _loadCompletedTasks() async {
    final ids = await StorageService.loadCompletedTaskIds();
    final dates = await StorageService.loadCompletedDates();
    final nextActive = _findNextIncompleteTaskFromIds(ids);
    setState(() {
      completedTaskIds = ids;
      completedDates = dates;
      if (nextActive != null) {
        currentLevel = nextActive.level;
        currentTaskNumber = nextActive.taskNumber;
      }
    });
  }

  Future<void> _loadUnlockAll() async {
    final value = await StorageService.getUnlockAll();
    setState(() => unlockAllLevels = value);
  }

  void _startTask() {
    final nextActive = _findNextIncompleteTask();
    final startLevel = nextActive?.level ?? currentLevel;
    final startTaskNumber = nextActive?.taskNumber ?? currentTaskNumber;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          currentLevel: startLevel,
          currentTaskNumber: startTaskNumber,
          onTaskComplete: _advanceTask,
        ),
      ),
    );
  }

  void _advanceTask(int level, int taskNumber) {
    setState(() {
      currentLevel = level;
      currentTaskNumber = taskNumber;
    });
    _loadStreak(); // Refresh streak after task completion
    _loadCompletedTasks();
  }

  Future<void> _resetAllProgress() async {
    await StorageService.resetAllProgress();
    setState(() {
      currentLevel = 1;
      currentTaskNumber = 1;
      streak = 0;
      completedTaskIds = {};
      unlockAllLevels = false;
    });
  }

  Future<void> _unlockAllLevels() async {
    await StorageService.setUnlockAll(true);
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

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  subtitle: const Text('Access any level without completing tasks'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _unlockAllLevels();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: const Text('Reset All Progress'),
                  subtitle: const Text('Factory reset: streaks, progress, and unlocks'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _resetAllProgress();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About'),
                  subtitle: const Text('A personal note from the developer'),
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

  Color _levelWatermarkColor(int level) {
    final start = const Color(0xFFB9C4D9);
    final mid = const Color(0xFF7DA6FF);
    final high = const Color(0xFFFFD07A);
    final t = (level - 1) / 19.0;
    if (t < 0.6) {
      return Color.lerp(start, mid, t / 0.6)!;
    }
    return Color.lerp(mid, high, (t - 0.6) / 0.4)!;
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

  int _badgeStars(int level) {
    final stars = (level / 4).ceil();
    return stars.clamp(1, 5);
  }

  Widget _buildLevelBadge() {
    final displayLevel = unlockAllLevels ? 20 : currentLevel;
    final colors = _badgeColors(displayLevel);
    final tier = (displayLevel / 4).ceil().clamp(1, 5);
    final glow = 0.25 + (displayLevel / 20.0) * 0.35;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.98 + (_pulseController.value * 0.04);
        return Transform.scale(
          scale: pulse,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(glow + (_pulseController.value * 0.1)),
                  blurRadius: 20 + displayLevel * 0.4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(36, 36),
                    painter: _BadgePainter(
                      t: displayLevel / 20.0,
                      colors: colors,
                      tier: tier,
                    ),
                    child: const SizedBox(width: 36, height: 36),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unlockAllLevels ? 'Level $displayLevel' : 'Level $currentLevel',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (unlockAllLevels)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'MAX LEVEL REACHED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Row(
                        children: List.generate(
                          _badgeStars(displayLevel),
                          (index) => const Padding(
                            padding: EdgeInsets.only(right: 2.0),
                            child: Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _badgeColors(int level) {
    final t = (level - 1) / 19.0;
    final h1 = (210 + 140 * math.sin(t * math.pi)).clamp(0, 360);
    final h2 = (h1 + 60 + 40 * math.cos(t * math.pi * 2)).clamp(0, 360);
    final s1 = 0.55 + 0.35 * math.sin(t * math.pi / 2);
    final s2 = 0.65 + 0.25 * math.cos(t * math.pi / 2);
    final l1 = 0.45 + 0.2 * t;
    final l2 = 0.55 + 0.2 * t;
    return [
      HSLColor.fromAHSL(1, h1.toDouble(), s1.clamp(0.4, 0.9), l1.clamp(0.3, 0.75))
          .toColor(),
      HSLColor.fromAHSL(1, h2.toDouble(), s2.clamp(0.4, 0.9), l2.clamp(0.35, 0.8))
          .toColor(),
    ];
  }

  Widget _buildStreakChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF5F6D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5F6D).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
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
                        return _DayCell(
                          day: dayNum,
                          isDone: isDone,
                        );
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
    int totalTasks = _getTotalTasksForLevel(currentLevel);
    final completedInLevel = allTasks
        .where((t) => t.level == currentLevel)
        .where((t) => completedTaskIds.contains(StorageService.taskId(t.level, t.taskNumber)))
        .length;
    double progress = (completedInLevel / totalTasks).clamp(0.0, 1.0);
    final overallProgress =
        (completedTaskIds.length / allTasks.length).clamp(0.0, 1.0);
    final nextActive = _findNextIncompleteTask();
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 370 ? 16.0 : 24.0;
    final gridCrossAxis = screenWidth < 360 ? 3 : 4;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kDeepBlue,
              kDeepPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Daily Communication Tips',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.robotoFlex(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            Shadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLevelBadge(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.calendar_month_rounded,
                                    color: Colors.white),
                                onPressed: _showCalendarDialog,
                                tooltip: 'Monthly progress',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStreakChip(),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.settings_rounded, color: Colors.white),
                                onPressed: _showSettingsSheet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Main Action Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROGRESS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}% Complete',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Overall: ${(overallProgress * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$completedInLevel',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'tasks mastered',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$totalTasks total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final clamped = progress.clamp(0.0, 1.0);
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: clamped),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              final barWidth = constraints.maxWidth * value;
                              final knobLeft =
                                  (barWidth - 14).clamp(0.0, constraints.maxWidth - 28);
                              return Stack(
                                children: [
                                  Container(
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 18,
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          kAccentPrimary,
                                          kAccentSecondary,
                                          kAccentTertiary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kAccentSecondary.withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Opacity(
                                        opacity: 0.35,
                                        child: Container(
                                          margin: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.2),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: knobLeft,
                                    top: -6,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: kAccentPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nextActive == null
                            ? 'Course complete. You finished all 20 levels.'
                            : 'Next up: Level ${nextActive.level} Task ${nextActive.taskNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F67FF),
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: const Color(0xFF5F67FF).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Start Today's Task",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                const Text(
                  'Your Path',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Levels Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxis,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    final levelIndex = index + 1;
                    final isLocked = !unlockAllLevels && levelIndex > currentLevel;
                    final isCompleted = levelIndex < currentLevel;
                    final isCurrent = levelIndex == currentLevel;
                    final levelColors = _badgeColors(levelIndex)
                        .map(
                          (c) => c.withOpacity(
                            isLocked ? 0.08 : isCompleted ? 0.35 : 0.6,
                          ),
                        )
                        .toList();

                    return GestureDetector(
                      onTap: () {
                        if (!isLocked) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelTasksScreen(
                                level: levelIndex,
                                onTaskComplete: _advanceTask,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: levelColors,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: isCurrent
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: [
                            if (isCurrent)
                              BoxShadow(
                                color: levelColors.last.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            if (!isCurrent)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(
                                    '$levelIndex',
                                    style: TextStyle(
                                      fontSize: 140,
                                      fontWeight: FontWeight.bold,
                                      color: _levelWatermarkColor(levelIndex)
                                          .withOpacity(isLocked ? 0.08 : 0.22),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: isLocked
                                  ? Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.5))
                                  : isCompleted
                                      ? const Icon(Icons.check_circle_rounded, color: Colors.white)
                                      : Text(
                                          '$levelIndex',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent
                                                ? const Color(0xFF764ba2)
                                                : Colors.white,
                                          ),
                                        ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
                color: isDone ? kAccentPrimary.withOpacity(0.8) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone ? kAccentPrimary : Colors.black12,
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

class _BadgePainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final int tier;

  _BadgePainter({
    required this.t,
    required this.colors,
    required this.tier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.48;
    final points = <Offset>[];
    final spikes = 6 + (t * 10).round();
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (math.pi * 2 * i) / (spikes * 2);
      final wave = 0.68 + 0.26 * math.sin(i * 0.9 + t * math.pi * 2);
      final radius = r * (i.isEven ? 1.0 : wave);
      points.add(Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ));
    }

    final path = Path()..addPolygon(points, true);
    final gradient = RadialGradient(
      colors: [colors.first, colors.last],
      center: Alignment(-0.3 + 0.6 * t, -0.2),
      radius: 0.9,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < tier; i++) {
      final ringR = r * (0.62 - i * 0.08);
      final sweep = math.pi * (1.2 + (i * 0.2)) + (t * math.pi * 0.6);
      final rect = Rect.fromCircle(center: center, radius: ringR);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, ringPaint);
    }

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r * 0.22, corePaint);

    final iconPaint = Paint()..color = Colors.white;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - r * 0.3)
      ..lineTo(center.dx + r * 0.2, center.dy)
      ..lineTo(center.dx, center.dy + r * 0.3)
      ..lineTo(center.dx - r * 0.2, center.dy)
      ..close();
    canvas.drawPath(diamond, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.colors != colors || oldDelegate.tier != tier;
  }
}



