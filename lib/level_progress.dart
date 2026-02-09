import 'package:daily_communication_tips/data/course_tasks.dart';

class LevelProgress {
  int currentLevel;
  int currentTaskNumber;

  LevelProgress({this.currentLevel = 1, this.currentTaskNumber = 1});

  DailyTask get currentTask {
    return allTasks.firstWhere(
      (t) => t.level == currentLevel && t.taskNumber == currentTaskNumber,
    );
  }

  void completeTask() {
    int nextTaskNumber = currentTaskNumber + 1;
    int nextLevel = currentLevel;

    if (nextTaskNumber > currentTask.totalTasks) {
      nextLevel += 1;
      nextTaskNumber = 1;
    }

    if (nextLevel > 20) {
      nextLevel = 20;
      nextTaskNumber = currentTask.totalTasks;
    }

    currentLevel = nextLevel;
    currentTaskNumber = nextTaskNumber;
  }
}

