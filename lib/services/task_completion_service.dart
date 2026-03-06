import '../models/task_model.dart';

class TaskCompletionService {
  static bool canCompleteNow(Task task, {DateTime? now}) {
    if (task.recurrence == TaskRecurrence.none) return true;
    final current = now ?? DateTime.now();

    switch (task.recurrence) {
      case TaskRecurrence.none:
        return true;
      case TaskRecurrence.daily:
      case TaskRecurrence.custom:
        return _isSameDay(current, task.dueDate);
      case TaskRecurrence.weekly:
        return _startOfWeek(current) == _startOfWeek(task.dueDate);
      case TaskRecurrence.monthly:
        return current.year == task.dueDate.year &&
            current.month == task.dueDate.month;
    }
  }

  static String blockedMessage(Task task) {
    switch (task.recurrence) {
      case TaskRecurrence.none:
        return '';
      case TaskRecurrence.daily:
        return 'Daily tasks can only be completed on their scheduled day.';
      case TaskRecurrence.weekly:
        return 'Weekly tasks can only be completed in their scheduled week.';
      case TaskRecurrence.monthly:
        return 'Monthly tasks can only be completed in their scheduled month.';
      case TaskRecurrence.custom:
        return 'Recurring tasks can only be completed on their scheduled day.';
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }
}
