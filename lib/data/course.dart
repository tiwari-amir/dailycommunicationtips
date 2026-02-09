class LevelTask {
  final int level;
  final String content;
  final int tasksRequired; // number of days/tasks to complete the level

  LevelTask({
    required this.level,
    required this.content,
    required this.tasksRequired,
  });
}

// Generate 20 levels dynamically
final List<LevelTask> courseLevels = List.generate(20, (index) {
  int lvl = index + 1;
  int tasksNeeded = 10 + index * 5; // progressive: 10,15,20,...
  
  String content = 'Level $lvl Task: ';
  
  if (lvl <= 5) {
    content += 'Focus on calm and clear communication today. '
        'Take your time to express yourself with confidence.';
  } else if (lvl <= 10) {
    content += 'Practice active listening and thoughtful responses. '
        'Notice your tone and body language.';
  } else if (lvl <= 15) {
    content += 'Work on articulating complex ideas clearly and with empathy. '
        'Reflect on feedback and adjust your approach.';
  } else {
    content += 'Engage in advanced communication: negotiate, inspire, and collaborate. '
        'Use precision, empathy, and confidence in every interaction.';
  }

  return LevelTask(level: lvl, content: content, tasksRequired: tasksNeeded);
});
