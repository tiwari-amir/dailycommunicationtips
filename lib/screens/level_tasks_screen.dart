import 'package:flutter/material.dart';
import 'package:daily_communication_tips/data/course_tasks.dart';
import 'package:daily_communication_tips/screens/reading_screen.dart';
import 'package:daily_communication_tips/services/storage_service.dart';

class LevelTasksScreen extends StatefulWidget {
  final int level;
  final void Function(int newLevel, int newTaskNumber)? onTaskComplete;

  const LevelTasksScreen({
    super.key,
    required this.level,
    this.onTaskComplete,
  });

  @override
  State<LevelTasksScreen> createState() => _LevelTasksScreenState();
}

class _LevelTasksScreenState extends State<LevelTasksScreen> {
  Set<String> completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    final ids = await StorageService.loadCompletedTaskIds();
    setState(() {
      completedTaskIds = ids;
    });
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

  void _goToCurrentActiveTask() {
    final nextActive = _findNextIncompleteTask();
    if (nextActive == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          currentLevel: nextActive.level,
          currentTaskNumber: nextActive.taskNumber,
          onTaskComplete: widget.onTaskComplete,
        ),
      ),
    );
  }

  LinearGradient _getLevelGradient(int level) {
    // Rarity Fade Progression:
    // Levels 1-3: Consumer (Cool Greys/Whites)
    // Levels 4-6: Industrial (Light Blues)
    // Levels 7-9: Mil-Spec (Deep Blues)
    // Levels 10-12: Restricted (Purples)
    // Levels 13-15: Classified (Pinks/Magentas)
    // Levels 16-18: Covert (Reds)
    // Levels 19-20: Special (Gold/Sunset)

    if (level <= 3) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
      );
    } else if (level <= 6) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF89F7FE), Color(0xFF66A6FF)],
      );
    } else if (level <= 9) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      );
    } else if (level <= 12) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
      );
    } else if (level <= 15) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
      );
    } else if (level <= 18) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = allTasks.where((t) => t.level == widget.level).toList();
    final nextActive = _findNextIncompleteTask();
    final showCurrentTaskButton = nextActive != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Level ${widget.level} Tasks',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _getLevelGradient(widget.level),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length + (showCurrentTaskButton ? 1 : 0),
            itemBuilder: (context, index) {
              if (showCurrentTaskButton && index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Jump back to your current active task',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _goToCurrentActiveTask,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Go'),
                      ),
                    ],
                  ),
                );
              }
              final taskIndex = showCurrentTaskButton ? index - 1 : index;
              final task = tasks[taskIndex];
              final isCompleted = completedTaskIds.contains(
                StorageService.taskId(task.level, task.taskNumber),
              );
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReadingScreen(
                        currentLevel: widget.level,
                        currentTaskNumber: task.taskNumber,
                        onTaskComplete: widget.onTaskComplete,
                      ),
                    ),
                  ).then((_) => _loadCompletedTasks());
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isCompleted ? 0.7 : 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCompleted)
                            const Icon(Icons.check_circle_rounded, color: Colors.green),
                          if (isCompleted) const SizedBox(width: 6),
                          Text(
                            'Task ${task.taskNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.content,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D3142),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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

