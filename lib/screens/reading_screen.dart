import 'package:flutter/material.dart';
import 'dart:async';
import 'package:daily_communication_tips/data/course_tasks.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ReadingScreen extends StatefulWidget {
  final int currentLevel;
  final int currentTaskNumber;
  final void Function(int newLevel, int newTaskNumber)? onTaskComplete;

  const ReadingScreen({
    super.key,
    required this.currentLevel,
    required this.currentTaskNumber,
    this.onTaskComplete,
  });

  @override
  _ReadingScreenState createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late int level;
  late int taskNumber;
  late DailyTask currentTask;
  bool isCompleted = false;
  Set<String> completedTaskIds = {};
  static const Duration _completeCooldown = Duration(seconds: 5);
  Duration _cooldownLeft = _completeCooldown;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    level = widget.currentLevel;
    taskNumber = widget.currentTaskNumber;
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
    setState(() {
      completedTaskIds = ids;
      isCompleted = ids.contains(StorageService.taskId(level, taskNumber));
    });
  }

  Future<void> _completeTask() async {
    if (isCompleted || _cooldownLeft > Duration.zero) return;

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
    if (newStreak == 7 || newStreak % 7 == 0) {
      await NotificationService.showStreakCongrats(newStreak);
    }
    await NotificationService.scheduleDailyReminder(
      time: const TimeOfDay(hour: 7, minute: 0),
    );
    await NotificationService.scheduleStreakReminder(
      time: const TimeOfDay(hour: 21, minute: 0),
    );
    await StorageService.markTaskCompleted(level, taskNumber);

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
  }

  bool get _hasNextTask {
    if (level >= 20 && taskNumber >= currentTask.totalTasks) {
      return false;
    }
    return true;
  }

  void _goToNextTask() {
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
      _loadTask();
      isCompleted = completedTaskIds.contains(StorageService.taskId(level, taskNumber));
    });
    _startCooldown();
  }

  void _goToCurrentActiveTask() {
    final nextActive = _findNextIncompleteTask();
    if (nextActive == null) return;
    setState(() {
      level = nextActive.level;
      taskNumber = nextActive.taskNumber;
      _loadTask();
      isCompleted = completedTaskIds.contains(StorageService.taskId(level, taskNumber));
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

  bool get _hasCurrentActiveTask {
    return _findNextIncompleteTask() != null;
  }

  @override
  Widget build(BuildContext context) {
    final cooldownProgress = 1 -
        (_cooldownLeft.inMilliseconds / _completeCooldown.inMilliseconds)
            .clamp(0.0, 1.0);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Level $level • Task $taskNumber'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
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
                            Color(0xFF7F7FD5),
                            Color(0xFF86A8E7),
                            Color(0xFF91EAE4),
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
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.6)),
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
                                    color: const Color(0xFF764ba2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Level $level',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF764ba2),
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
                                    color: const Color(0xFF667eea).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Task $taskNumber',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF667eea),
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
                                color: Color(0xFF2D3142),
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
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? Colors.green : const Color(0xFF5F67FF),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            (isCompleted || _cooldownLeft > Duration.zero) ? null : _completeTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCompleted ? Colors.green : const Color(0xFF5F67FF),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0xFF5F67FF).withOpacity(0.4),
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
                if (_hasNextTask)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isCompleted ? _goToNextTask : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Do Next Task'),
                    ),
                  ),
                if (isCompleted && _hasCurrentActiveTask)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextButton(
                      onPressed: _goToCurrentActiveTask,
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Go to Current Active Task'),
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

