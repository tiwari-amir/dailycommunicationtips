import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String streakKey = 'streak';
  static const String lastDateKey = 'lastCompletedDate';
  static const String levelKey = 'level';
  static const String tasksKey = 'tasksCompleted';
  static const String completedTaskIdsKey = 'completedTaskIds';
  static const String unlockAllKey = 'unlockAll';

  static Future<int> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    int streak = prefs.getInt(streakKey) ?? 0;
    String? lastDateString = prefs.getString(lastDateKey);
    DateTime now = DateTime.now();

    if (lastDateString == null) {
      streak = 1;
      await prefs.setInt(streakKey, streak);
      await prefs.setString(lastDateKey, now.toIso8601String());
    } else {
      DateTime lastDate = DateTime.parse(lastDateString);
      int hoursDiff = now.difference(lastDate).inHours;

      if (hoursDiff >= 48) {
        // Streak lost (more than 48 hours passed)
        streak = 1;
        await prefs.setInt(streakKey, streak);
        await prefs.setString(lastDateKey, now.toIso8601String());
      } else if (hoursDiff >= 24) {
        // Streak increment (between 24 and 48 hours)
        streak++;
        await prefs.setInt(streakKey, streak);
        await prefs.setString(lastDateKey, now.toIso8601String());
      }
      // If < 24 hours, do nothing (maintain streak, don't update time)
    }
    return streak;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    int streak = prefs.getInt(streakKey) ?? 0;
    String? lastDateString = prefs.getString(lastDateKey);
    
    if (lastDateString != null) {
      DateTime lastDate = DateTime.parse(lastDateString);
      // If more than 48 hours have passed, show 0 (streak lost)
      if (DateTime.now().difference(lastDate).inHours >= 48) {
        return 0;
      }
    }
    return streak;
  }

  static Future<void> saveLevelXP(int level, int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(levelKey, level);
  }

  static Future<Map<String, int>> loadLevelXP() async {
    final prefs = await SharedPreferences.getInstance();
    int level = prefs.getInt(levelKey) ?? 1;
    return {'level': level, 'xp': 0};
  }

  static Future<void> saveTasksCompleted(int tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(tasksKey, tasks);
  }

  static Future<int> loadTasksCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(tasksKey) ?? 0;
  }

  static Future<DateTime?> getLastCompletedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateString = prefs.getString(lastDateKey);
    if (lastDateString == null) return null;
    return DateTime.tryParse(lastDateString);
  }

  static String taskId(int level, int taskNumber) => 'L$level-T$taskNumber';

  static Future<Set<String>> loadCompletedTaskIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(completedTaskIdsKey) ?? <String>[];
    return ids.toSet();
  }

  static Future<void> markTaskCompleted(int level, int taskNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(completedTaskIdsKey) ?? <String>[];
    final id = taskId(level, taskNumber);
    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList(completedTaskIdsKey, ids);
    }
  }

  static Future<bool> isTaskCompleted(int level, int taskNumber) async {
    final ids = await loadCompletedTaskIds();
    return ids.contains(taskId(level, taskNumber));
  }

  static Future<void> setUnlockAll(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(unlockAllKey, value);
  }

  static Future<bool> getUnlockAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(unlockAllKey) ?? false;
  }

  static Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(streakKey);
    await prefs.remove(lastDateKey);
    await prefs.remove(levelKey);
    await prefs.remove(tasksKey);
    await prefs.remove(completedTaskIdsKey);
    await prefs.remove(unlockAllKey);
  }
}
