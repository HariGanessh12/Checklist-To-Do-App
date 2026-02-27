import '../models/task_model.dart';

class ProductivityStats {
  final int totalTasks;
  final int completedTasks;
  final double completionRate; // 0..1
  final int currentStreakDays;
  final double averageDelayHours;

  const ProductivityStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.currentStreakDays,
    required this.averageDelayHours,
  });
}

class ProductivityStatsService {
  static ProductivityStats compute(List<Task> tasks, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final completed = tasks.where((task) => task.isCompleted).toList();
    final totalCount = tasks.length;
    final completedCount = completed.length;
    final completionRate = totalCount == 0 ? 0.0 : completedCount / totalCount;

    final streak = _computeStreakDays(completed, current);
    final avgDelay = _computeAverageDelayHours(completed);

    return ProductivityStats(
      totalTasks: totalCount,
      completedTasks: completedCount,
      completionRate: completionRate,
      currentStreakDays: streak,
      averageDelayHours: avgDelay,
    );
  }

  static int _computeStreakDays(List<Task> completedTasks, DateTime now) {
    if (completedTasks.isEmpty) return 0;

    final doneDays = <DateTime>{};
    for (final task in completedTasks) {
      final completedAt = task.completedAt;
      if (completedAt == null) continue;
      doneDays.add(
        DateTime(completedAt.year, completedAt.month, completedAt.day),
      );
    }
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
      if (completedAt == null) continue;
      final hours = completedAt.difference(task.dueDate).inMinutes / 60.0;
      delays.add(hours);
    }
    if (delays.isEmpty) return 0.0;
    final sum = delays.fold<double>(0.0, (prev, hours) => prev + hours);
    return sum / delays.length;
  }
}
