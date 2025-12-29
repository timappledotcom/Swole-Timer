/// Model class representing a daily walk log entry
class DailyWalk {
  final DateTime date;
  final bool completed;
  final int? durationMinutes;
  final String? notes;

  DailyWalk({
    required this.date,
    required this.completed,
    this.durationMinutes,
    this.notes,
  });

  /// Get the date without time component (for comparison)
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  /// Create DailyWalk from JSON map
  factory DailyWalk.fromJson(Map<String, dynamic> json) {
    return DailyWalk(
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
      durationMinutes: json['durationMinutes'] as int?,
      notes: json['notes'] as String?,
    );
  }

  /// Convert DailyWalk to JSON map
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completed': completed,
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  /// Create a copy with updated fields
  DailyWalk copyWith({
    DateTime? date,
    bool? completed,
    int? durationMinutes,
    String? notes,
  }) {
    return DailyWalk(
      date: date ?? this.date,
      completed: completed ?? this.completed,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
    );
  }

  /// Check if this walk is from today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dateOnly.isAtSameMomentAs(today);
  }

  /// Check if this walk is from a specific date
  bool isOnDate(DateTime other) {
    final otherDateOnly = DateTime(other.year, other.month, other.day);
    return dateOnly.isAtSameMomentAs(otherDateOnly);
  }

  @override
  String toString() {
    return 'DailyWalk(date: $dateOnly, completed: $completed, duration: $durationMinutes min)';
  }
}

/// Statistics for walks over a period
class WalkStatistics {
  final int totalDays;
  final int completedDays;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  WalkStatistics({
    required this.totalDays,
    required this.completedDays,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    this.periodStart,
    this.periodEnd,
  });

  /// Completion rate as a percentage (0-100)
  double get completionRate =>
      totalDays > 0 ? (completedDays / totalDays) * 100 : 0;

  /// Average duration per walk in minutes
  double get averageDuration =>
      completedDays > 0 ? totalMinutes / completedDays : 0;

  /// Create empty statistics
  factory WalkStatistics.empty() {
    return WalkStatistics(
      totalDays: 0,
      completedDays: 0,
      totalMinutes: 0,
      currentStreak: 0,
      longestStreak: 0,
    );
  }

  /// Calculate statistics from a list of walks
  factory WalkStatistics.fromWalks(
    List<DailyWalk> walks, {
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    if (walks.isEmpty) return WalkStatistics.empty();

    // Sort by date descending
    final sorted = List<DailyWalk>.from(walks)
      ..sort((a, b) => b.date.compareTo(a.date));

    final completedWalks = sorted.where((w) => w.completed).toList();
    final totalMinutes = completedWalks.fold<int>(
      0,
      (sum, w) => sum + (w.durationMinutes ?? 30),
    );

    // Calculate current streak (consecutive days from today)
    int currentStreak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    for (final walk in sorted) {
      if (walk.completed && walk.dateOnly.isAtSameMomentAs(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (walk.dateOnly.isBefore(checkDate)) {
        break;
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final walk in sorted.reversed) {
      if (walk.completed) {
        if (lastDate == null ||
            walk.dateOnly.difference(lastDate).inDays == 1) {
          tempStreak++;
          longestStreak =
              tempStreak > longestStreak ? tempStreak : longestStreak;
        } else {
          tempStreak = 1;
        }
        lastDate = walk.dateOnly;
      } else {
        tempStreak = 0;
        lastDate = null;
      }
    }

    return WalkStatistics(
      totalDays: walks.length,
      completedDays: completedWalks.length,
      totalMinutes: totalMinutes,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}
