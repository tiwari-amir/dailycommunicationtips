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
      theme: ThemeData(primarySwatch: Colors.blue),
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
    if (!mounted) return;
    setState(() => unlockAllLevels = value);
    if (value) {
      await _markAllTasksCompleted();
    }
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
                    kAccentSecondary,
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

  Widget _buildProgressRing(double progress, int percent) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            height: 140,
            child: ShaderMask(
              shaderCallback: (rect) {
                return SweepGradient(
                  startAngle: -math.pi / 2,
                  endAngle: (math.pi * 2) - (math.pi / 2),
                  colors: const [
                    kAccentPrimary,
                    kAccentSecondary,
                    kAccentTertiary,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ).createShader(rect);
              },
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  Text(
                    'Overall',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
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
    const smallTalkTotal = 0;
    const smallTalkCompleted = 0;
    final totalTasks = communicationTotal + smallTalkTotal;
    final totalCompleted = communicationCompleted + smallTalkCompleted;
    final overallProgress = unlockAllLevels || totalTasks == 0
        ? 1.0
        : (totalCompleted / totalTasks).clamp(0.0, 1.0);
    final overallPercent = (overallProgress * 100).round();
    final communicationPercent = communicationTotal == 0
        ? 0
        : ((communicationCompleted / communicationTotal) * 100).round();
    final smallTalkPercent = smallTalkTotal == 0
        ? 0
        : ((smallTalkCompleted / smallTalkTotal) * 100).round();
    final communicationComplete =
        communicationTotal == 0 || communicationCompleted == communicationTotal;
    final smallTalkComplete =
        smallTalkTotal == 0 || smallTalkCompleted == smallTalkTotal;
    final allSectionsComplete = communicationComplete && smallTalkComplete;
    final gatedLevel = unlockAllLevels || allSectionsComplete
        ? currentLevel
        : math.min(currentLevel, 19);
    final sectionProgress = [
      {'label': 'Communication', 'percent': communicationPercent},
      {'label': 'Small talk', 'percent': smallTalkPercent},
    ];
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
            colors: [kDeepBlue, kDeepPurple],
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
                    Image.asset(
                      'assets/images/title.png',
                      height: 84,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildLevelBadge(gatedLevel),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                ),
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
                                icon: const Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                ),
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
                      colors: [
                        Color(0xFF7F7FD5),
                        Color(0xFF86A8E7),
                        Color(0xFF91EAE4),
                      ],
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: overallProgress,
                                    ),
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return _buildProgressRing(
                                        value,
                                        overallPercent,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: _startTask,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF5F67FF,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Do task',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SECTION PROGRESS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...sectionProgress.map(
                                  (section) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildMiniRing(
                                      section['percent'] as int,
                                      section['label'] as String,
                                      sectionProgress.length,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  allSectionsComplete
                                      ? 'Course complete. You finished all 20 levels.'
                                      : nextActive == null
                                      ? 'Complete other sections to reach Level 20.'
                                      : 'Next up: Level ${nextActive.level} Task ${nextActive.taskNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                _SectionCard(
                  title: 'Communication tips',
                  subtitle: 'Levels, tasks, and mastery',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SectionsScreen(
                          initialIndex: 0,
                          gatedLevel: gatedLevel,
                          unlockAllLevels: unlockAllLevels,
                          onTaskComplete: _advanceTask,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Small talk expert',
                  subtitle: 'Coming soon',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SectionsScreen(
                          initialIndex: 1,
                          gatedLevel: gatedLevel,
                          unlockAllLevels: unlockAllLevels,
                          onTaskComplete: _advanceTask,
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
            colors: [kDeepBlue, kDeepPurple],
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
                    ? kAccentPrimary.withOpacity(0.8)
                    : Colors.transparent,
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
