import '../models/task_model.dart';

class ProductivityStats {
  final int totalTasks;
  final int completedTasks;
  final double completionRate; // 0..1
  final double averageDelayHours;
  final List<TaskStreakStat> taskStreaks;

  const ProductivityStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.averageDelayHours,
    required this.taskStreaks,
  });
}

class TaskStreakStat {
  final String key;
  final String title;
  final String groupId;
  final int streakDays;

  const TaskStreakStat({
    required this.key,
    required this.title,
    required this.groupId,
    required this.streakDays,
  });
}

class ProductivityStatsService {
  static ProductivityStats compute(List<Task> tasks, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final completed = tasks.where((task) => task.isCompleted).toList();
    final totalCount = tasks.length;
    final completedCount = completed.length;
    final completionRate = totalCount == 0 ? 0.0 : completedCount / totalCount;

    final taskStreaks = _computeTaskStreaks(tasks, current);
    final avgDelay = _computeAverageDelayHours(completed);

    return ProductivityStats(
      totalTasks: totalCount,
      completedTasks: completedCount,
      completionRate: completionRate,
      averageDelayHours: avgDelay,
      taskStreaks: taskStreaks,
    );
  }

  static List<TaskStreakStat> _computeTaskStreaks(
    List<Task> tasks,
    DateTime now,
  ) {
    final tracked = tasks.where((task) => task.streakEnabled).toList();
    if (tracked.isEmpty) return const [];

    final grouped = <String, List<Task>>{};
    for (final task in tracked) {
      final key = _seriesKey(task);
      grouped.putIfAbsent(key, () => <Task>[]).add(task);
    }

    final result = <TaskStreakStat>[];
    grouped.forEach((key, seriesTasks) {
      seriesTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latest = seriesTasks.first;
      final doneDays = <DateTime>{};
      for (final task in seriesTasks) {
        final completedAt = task.completedAt;
        if (completedAt == null) continue;
        doneDays.add(
          DateTime(completedAt.year, completedAt.month, completedAt.day),
        );
      }
      final streak = _computeDayStreak(doneDays, now);
      result.add(
        TaskStreakStat(
          key: key,
          title: latest.title,
          groupId: latest.groupId,
          streakDays: streak,
        ),
      );
    });

    result.sort((a, b) {
      final streakCompare = b.streakDays.compareTo(a.streakDays);
      if (streakCompare != 0) return streakCompare;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return result;
  }

  static int _computeDayStreak(Set<DateTime> doneDays, DateTime now) {
    if (doneDays.isEmpty) return 0;
    var cursor = DateTime(now.year, now.month, now.day);
    if (!doneDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!doneDays.contains(cursor)) return 0;
    }

    var streak = 0;
    while (doneDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static double _computeAverageDelayHours(List<Task> completedTasks) {
    final delays = <double>[];
    for (final task in completedTasks) {
      final completedAt = task.completedAt;
      final dueDate = task.dueDate;
      if (completedAt == null || dueDate == null) continue;
      final hours = completedAt.difference(dueDate).inMinutes / 60.0;
      delays.add(hours);
    }
    if (delays.isEmpty) return 0.0;
    final sum = delays.fold<double>(0.0, (prev, hours) => prev + hours);
    return sum / delays.length;
  }

  static String _seriesKey(Task task) {
    return '${task.groupId}::${task.title.trim().toLowerCase()}';
  }
}
