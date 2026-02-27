import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';

class TaskDetailSheet extends StatelessWidget {
  final Task task;
  final TaskGroup? group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        !task.isCompleted && task.dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(
                    group?.colorValue ?? 0xFF6750A4,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  group?.icon ?? '📥',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      group?.name ?? "Individual",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (task.description.isNotEmpty) ...[
            const Text(
              "Notes",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(task.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
          ],
          const Text(
            "Schedule",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: isOverdue ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM dd • hh:mm a').format(task.dueDate),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
          if (task.recurrence != TaskRecurrence.none) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  _recurrenceLabel(task),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text("Edit"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_rounded, color: Colors.red.shade700),
                  label: Text(
                    "Delete",
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _recurrenceLabel(Task task) {
    switch (task.recurrence) {
      case TaskRecurrence.none:
        return 'No repeat';
      case TaskRecurrence.daily:
        return 'Repeats daily';
      case TaskRecurrence.weekly:
        return 'Repeats weekly';
      case TaskRecurrence.custom:
        final days = task.recurrenceIntervalDays ?? 1;
        return 'Repeats every $days day${days == 1 ? '' : 's'}';
    }
  }
}
