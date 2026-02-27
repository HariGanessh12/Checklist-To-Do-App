import 'package:uuid/uuid.dart';

import '../models/task_model.dart';

class RecurrenceService {
  static Task? nextOccurrenceFor(Task task, {DateTime? now}) {
    if (task.recurrence == TaskRecurrence.none) return null;

    final current = now ?? DateTime.now();
    final intervalDays = _intervalDays(task);
    var nextDue = task.dueDate.add(Duration(days: intervalDays));

    while (!nextDue.isAfter(current)) {
      nextDue = nextDue.add(Duration(days: intervalDays));
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
      notificationEnabled: task.notificationEnabled,
      recurrence: task.recurrence,
      recurrenceIntervalDays: task.recurrenceIntervalDays,
      subtasks: task.subtasks
          .map((subtask) => subtask.copyWith(isCompleted: false))
          .toList(),
      createdAt: current,
    );
  }

  static int _intervalDays(Task task) {
    switch (task.recurrence) {
      case TaskRecurrence.none:
        return 0;
      case TaskRecurrence.daily:
        return 1;
      case TaskRecurrence.weekly:
        return 7;
      case TaskRecurrence.custom:
        return (task.recurrenceIntervalDays ?? 1).clamp(1, 3650);
    }
  }
}
