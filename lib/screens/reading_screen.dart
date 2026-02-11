import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:daily_communication_tips/data/course_tasks.dart';
import '../services/gamification_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

class ReadingScreen extends StatefulWidget {
  final int currentLevel;
  final int currentTaskNumber;
  final void Function(int newLevel, int newTaskNumber)? onTaskComplete;
  final bool openedFromCompletedTask;

  const ReadingScreen({
    super.key,
    required this.currentLevel,
    required this.currentTaskNumber,
    this.onTaskComplete,
    this.openedFromCompletedTask = false,
  });

  @override
  _ReadingScreenState createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late int level;
  late int taskNumber;
  late DailyTask currentTask;
  bool isCompleted = false;
  bool unlockAllLevels = false;
  bool _allowActivePrompt = false;
  Set<String> completedTaskIds = {};
  static const Duration _completeCooldown = Duration(seconds: 5);
  Duration _cooldownLeft = _completeCooldown;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    level = widget.currentLevel;
    taskNumber = widget.currentTaskNumber;
    _allowActivePrompt = widget.openedFromCompletedTask;
    StorageService.markTodayTaskOpened();
    NotificationService.syncPinnedNotificationState();
    _loadTask();
    _loadCompletionState();
    _startCooldown();
  }

  void _loadTask() {
    currentTask = allTasks.firstWhere(
      (t) => t.level == level && t.taskNumber == taskNumber,
      orElse: () => allTasks.last,
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownLeft = _completeCooldown;
    });
    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      if (_cooldownLeft <= const Duration(milliseconds: 100)) {
        timer.cancel();
        setState(() {
          _cooldownLeft = Duration.zero;
        });
        return;
      }
      setState(() {
        _cooldownLeft -= const Duration(milliseconds: 100);
      });
    });
  }

  Future<void> _loadCompletionState() async {
    final ids = await StorageService.loadCompletedTaskIds();
    final unlocked = await StorageService.getUnlockAll();
    setState(() {
      completedTaskIds = ids;
      unlockAllLevels = unlocked;
      isCompleted = ids.contains(StorageService.taskId(level, taskNumber));
    });
  }

  Future<void> _completeTask() async {
    if (isCompleted || _cooldownLeft > Duration.zero) return;

    final previousLevel = level;
    int nextTaskNumber = taskNumber + 1;
    int nextLevel = level;

    // Check if level completed
    if (nextTaskNumber > currentTask.totalTasks) {
      nextLevel += 1;
      nextTaskNumber = 1;
    }

    // Cap at level 20
    if (nextLevel > 20) {
      nextLevel = 20;
      nextTaskNumber = currentTask.totalTasks;
      // Optional: Show "Course Completed" dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You have completed the full 20-level course!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    // Update streak based on time rules
    final newStreak = await StorageService.updateStreak();
    
    // Calculate Freeze Rewards
    int freezesEarned = 0;
    if (newStreak == 4) {
      freezesEarned = 2;
    } else if (newStreak == 10) {
      freezesEarned = 2;
    } else if (newStreak > 10 && (newStreak - 10) % 10 == 0) {
      freezesEarned = 1;
    }

    if (freezesEarned > 0) {
      await _addFreezes(freezesEarned);
      if (mounted) _showFreezeRewardAnimation(freezesEarned);
    }

    if (newStreak == 7 || newStreak % 7 == 0) {
      await NotificationService.showStreakCongrats(newStreak);
    }
    await NotificationService.scheduleDailyReminder(
      time: const TimeOfDay(hour: 8, minute: 0),
    );
    await StorageService.markTaskCompleted(level, taskNumber);
    await StorageService.markCompletionDate(DateTime.now());
    await StorageService.markTodayTaskDone();

    // Cancel streak expiry notifications
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    for (int id in [1001, 1002, 1003, 1004]) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
    await NotificationService.syncPinnedNotificationState();

    // Notify parent
    completedTaskIds.add(StorageService.taskId(level, taskNumber));
    final nextActive = _findNextIncompleteTask();
    if (nextActive != null) {
      widget.onTaskComplete?.call(nextActive.level, nextActive.taskNumber);
    } else {
      widget.onTaskComplete?.call(nextLevel, nextTaskNumber);
    }
    setState(() {
      isCompleted = true;
    });

    // Subtle, meaningful milestone feedback when a new badge tier is reached.
    if (GamificationService.unlockedNewBadge(
      previousLevel: previousLevel,
      nextLevel: nextLevel,
    )) {
      final badgeName = GamificationService.currentBadgeName(nextLevel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text('New badge unlocked: $badgeName'),
          ),
        );
      }
    }
  }

  Future<void> _addFreezes(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('freeze_count') ?? 3;
    await prefs.setInt('freeze_count', current + amount);
  }

  void _showFreezeRewardAnimation(int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: AlertDialog(
                backgroundColor: AppColors.bgCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ac_unit_rounded, color: Colors.blue, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '+$amount Freezes Earned!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Keep up the great work!', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Awesome'),
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

  bool get _hasNextTask {
    if (level >= 20 && taskNumber >= currentTask.totalTasks) {
      return false;
    }
    return true;
  }

  _TaskRef? _nextSequentialTask(int fromLevel, int fromTaskNumber) {
    final currentIndex = allTasks.indexWhere(
      (t) => t.level == fromLevel && t.taskNumber == fromTaskNumber,
    );
    if (currentIndex < 0 || currentIndex + 1 >= allTasks.length) return null;
    final next = allTasks[currentIndex + 1];
    return _TaskRef(next.level, next.taskNumber);
  }

  bool get _isViewingActiveTask {
    final active = _findNextIncompleteTask();
    if (active == null) return false;
    return active.level == level && active.taskNumber == taskNumber;
  }

  bool get _canGoToNextTask {
    if (!_hasNextTask) return false;
    if (unlockAllLevels) return true;
    if (_isViewingActiveTask) return false;
    final next = _nextSequentialTask(level, taskNumber);
    if (next == null) return false;
    return completedTaskIds.contains(
      StorageService.taskId(next.level, next.taskNumber),
    );
  }

  bool get _showGoToActivePrompt {
    final active = _findNextIncompleteTask();
    if (active == null) return false;
    return _allowActivePrompt && isCompleted && !_isViewingActiveTask;
  }

  void _goToNextTask() {
    if (!_canGoToNextTask) return;
    int nextTaskNumber = taskNumber + 1;
    int nextLevel = level;

    if (nextTaskNumber > currentTask.totalTasks) {
      nextLevel += 1;
      nextTaskNumber = 1;
    }

    if (nextLevel > 20) {
      return;
    }

    setState(() {
      level = nextLevel;
      taskNumber = nextTaskNumber;
      _allowActivePrompt = false;
      _loadTask();
      isCompleted = completedTaskIds.contains(
        StorageService.taskId(level, taskNumber),
      );
    });
    _startCooldown();
  }

  void _goToCurrentActiveTask() {
    final nextActive = _findNextIncompleteTask();
    if (nextActive == null) return;
    setState(() {
      level = nextActive.level;
      taskNumber = nextActive.taskNumber;
      _allowActivePrompt = false;
      _loadTask();
      isCompleted = completedTaskIds.contains(
        StorageService.taskId(level, taskNumber),
      );
    });
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final cooldownProgress =
        1 -
        (_cooldownLeft.inMilliseconds / _completeCooldown.inMilliseconds).clamp(
          0.0,
          1.0,
        );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reading Task',
          style: TextStyle(color: AppColors.textPrimary),
        ),
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accentPrimary,
                            AppColors.accentFocus,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.progressTrack),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgElevated,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Level $level',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgElevated,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Task $taskNumber',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentTask.content,
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LinearProgressIndicator(
                            value: cooldownProgress,
                            backgroundColor: AppColors.progressTrack,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? AppColors.progressGood
                                  : AppColors.accentPrimary,
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            (isCompleted || _cooldownLeft > Duration.zero)
                            ? null
                            : _completeTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted
                              ? AppColors.progressGood
                              : AppColors.accentPrimary,
                          foregroundColor: AppColors.textPrimary,
                          elevation: 6,
                          shadowColor: AppColors.accentPrimary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isCompleted) ...[
                              const Icon(Icons.check_circle_rounded),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isCompleted
                                  ? 'Completed'
                                  : _cooldownLeft > Duration.zero
                                  ? 'Hold on... ${_cooldownLeft.inSeconds + 1}s'
                                  : 'Mark Task as Completed',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_canGoToNextTask)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _goToNextTask,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.progressTrack),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Do Next Task'),
                    ),
                  ),
                if (_showGoToActivePrompt)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextButton(
                      onPressed: _goToCurrentActiveTask,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Go to Active Task'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Close'),
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
