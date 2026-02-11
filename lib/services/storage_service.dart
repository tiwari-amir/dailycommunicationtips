import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String streakKey = 'streak';
  static const String bestStreakKey = 'bestStreak';
  static const String lastDateKey = 'lastCompletedDate';
  static const String levelKey = 'level';
  static const String tasksKey = 'tasksCompleted';
  static const String completedTaskIdsKey = 'completedTaskIds';
  static const String unlockAllKey = 'unlockAll';
  static const String completedDatesKey = 'completedDates';
  static const String pinTodayTaskInPanelKey = 'pinTodayTaskInPanel';
  static const String todayTaskOpenedKey = 'todayTaskOpened';
  static const String todayTaskDoneKey = 'todayTaskDone';
  static const String todayTaskDateKey = 'todayTaskDate';

  static Future<int> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    int streak = prefs.getInt(streakKey) ?? 0;
    int bestStreak = prefs.getInt(bestStreakKey) ?? 0;
    String? lastDateString = prefs.getString(lastDateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastDateString == null) {
      streak = 1;
      await prefs.setInt(streakKey, streak);
      await prefs.setString(lastDateKey, now.toIso8601String());
    } else {
      final lastDate = DateTime.parse(lastDateString);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final dayDiff = today.difference(lastDay).inDays;

      if (dayDiff == 0) {
        return streak;
      } else if (dayDiff == 1) {
        streak++;
        await prefs.setInt(streakKey, streak);
        await prefs.setString(lastDateKey, now.toIso8601String());
      } else {
        streak = 1;
        await prefs.setInt(streakKey, streak);
        await prefs.setString(lastDateKey, now.toIso8601String());
      }
    }
    if (streak > bestStreak) {
      await prefs.setInt(bestStreakKey, streak);
    }
    return streak;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(streakKey) ?? 0;
    String? lastDateString = prefs.getString(lastDateKey);

    if (lastDateString != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastDate = DateTime.parse(lastDateString);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (today.difference(lastDay).inDays > 1) {
        return 0;
      }
    }
    return streak;
  }

  static Future<int> getBestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(bestStreakKey) ?? 0;
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

  static Future<void> setCompletedTaskIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(completedTaskIdsKey, ids.toList());
  }

  static Future<void> markCompletionDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(completedDatesKey) ?? <String>[];
    final dayKey = _dateKey(date);
    if (!dates.contains(dayKey)) {
      dates.add(dayKey);
      await prefs.setStringList(completedDatesKey, dates);
    }
  }

  static Future<Set<String>> loadCompletedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(completedDatesKey) ?? <String>[];
    return dates.toSet();
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  static Future<void> setPinTodayTaskInPanel(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pinTodayTaskInPanelKey, value);
  }

  static Future<bool> getPinTodayTaskInPanel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pinTodayTaskInPanelKey) ?? false;
  }

  static Future<void> resetDailyNotificationFlagsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final savedDate = prefs.getString(todayTaskDateKey);
    if (savedDate == today) return;
    await prefs.setString(todayTaskDateKey, today);
    await prefs.setBool(todayTaskOpenedKey, false);
    await prefs.setBool(todayTaskDoneKey, false);
  }

  static Future<void> markTodayTaskOpened() async {
    await resetDailyNotificationFlagsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(todayTaskOpenedKey, true);
  }

  static Future<void> markTodayTaskDone() async {
    await resetDailyNotificationFlagsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(todayTaskDoneKey, true);
  }

  static Future<bool> isTodayTaskOpened() async {
    await resetDailyNotificationFlagsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(todayTaskOpenedKey) ?? false;
  }

  static Future<bool> isTodayTaskDone() async {
    await resetDailyNotificationFlagsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(todayTaskDoneKey) ?? false;
  }

  static Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(levelKey);
    await prefs.remove(tasksKey);
    await prefs.remove(completedTaskIdsKey);
    await prefs.remove(completedDatesKey);
    await prefs.remove(unlockAllKey);
    await prefs.remove(pinTodayTaskInPanelKey);
    await prefs.remove(todayTaskOpenedKey);
    await prefs.remove(todayTaskDoneKey);
    await prefs.remove(todayTaskDateKey);
  }
}
