import 'package:uuid/uuid.dart';
import 'dart:math';

import '../models/task_model.dart';

class RecurrenceService {
  static List<Task> rollOverMissedDailyTasks(
    List<Task> tasks, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    var changed = false;

    final updated = tasks.map((task) {
      if (task.isCompleted || task.recurrence != TaskRecurrence.daily) {
        return task;
      }
      if (!task.dueDate.isBefore(todayStart)) {
        return task;
      }

      changed = true;
      final rolledDueDate = DateTime(
        todayStart.year,
        todayStart.month,
        todayStart.day,
        task.dueDate.hour,
        task.dueDate.minute,
        task.dueDate.second,
        task.dueDate.millisecond,
        task.dueDate.microsecond,
      );

      return task.copyWith(
        dueDate: rolledDueDate,
        subtasks: task.subtasks
            .map((subtask) => subtask.copyWith(isCompleted: false))
            .toList(),
      );
    }).toList();

    return changed ? updated : tasks;
  }

  static Task? nextOccurrenceFor(Task task, {DateTime? now}) {
    if (task.recurrence == TaskRecurrence.none) return null;

    final current = now ?? DateTime.now();
    var nextDue = _advance(task.dueDate, task);

    while (!nextDue.isAfter(current)) {
      nextDue = _advance(nextDue, task);
    }

    return Task(
      id: const Uuid().v4(),
      groupId: task.groupId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: nextDue,
      isCompleted: false,
      isPinned: task.isPinned,
      streakEnabled: task.streakEnabled,
      notificationEnabled: task.notificationEnabled,
      recurrence: task.recurrence,
      recurrenceIntervalDays: task.recurrenceIntervalDays,
      subtasks: task.subtasks
          .map((subtask) => subtask.copyWith(isCompleted: false))
          .toList(),
      createdAt: current,
    );
  }

  static DateTime _advance(DateTime from, Task task) {
    switch (task.recurrence) {
      case TaskRecurrence.none:
        return from;
      case TaskRecurrence.daily:
        return from.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return from.add(const Duration(days: 7));
      case TaskRecurrence.custom:
        final days = (task.recurrenceIntervalDays ?? 1).clamp(1, 3650);
        return from.add(Duration(days: days));
      case TaskRecurrence.monthly:
        return _addMonths(from, 1);
    }
  }

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final zeroBasedMonth = date.month - 1 + monthsToAdd;
    final year = date.year + (zeroBasedMonth ~/ 12);
    final month = (zeroBasedMonth % 12) + 1;
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = min(date.day, maxDay);
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
