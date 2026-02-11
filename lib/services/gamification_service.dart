class GamificationService {
  const GamificationService._();

  static const List<int> milestoneLevels = [1, 3, 5, 8, 12, 16, 20];

  static const Map<int, String> _badgeNames = {
    1: 'Starter Voice',
    3: 'Active Listener',
    5: 'Clear Speaker',
    8: 'Empathy Builder',
    12: 'Conflict Navigator',
    16: 'Conversation Leader',
    20: 'Calm Communicator',
  };

  static String currentBadgeName(int level) {
    final milestone = _currentMilestone(level);
    return _badgeNames[milestone] ?? 'Starter Voice';
  }

  static int unlockedBadgeCount(int level) {
    return milestoneLevels
        .where((m) => m <= level)
        .length
        .clamp(0, milestoneLevels.length);
  }

  static int? nextBadgeMilestone(int level) {
    for (final milestone in milestoneLevels) {
      if (milestone > level) return milestone;
    }
    return null;
  }

  static String? nextBadgeName(int level) {
    final milestone = nextBadgeMilestone(level);
    if (milestone == null) return null;
    return _badgeNames[milestone];
  }

  static bool unlockedNewBadge({
    required int previousLevel,
    required int nextLevel,
  }) {
    final before = _currentMilestone(previousLevel);
    final after = _currentMilestone(nextLevel);
    return after > before;
  }

  static int _currentMilestone(int level) {
    var current = milestoneLevels.first;
    for (final milestone in milestoneLevels) {
      if (milestone <= level) {
        current = milestone;
      } else {
        break;
      }
    }
    return current;
  }
}
