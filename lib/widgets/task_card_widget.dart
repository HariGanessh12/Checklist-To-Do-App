import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final TaskGroup? group;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback? onPinToggle;
  final VoidCallback? onNotify;
  final bool showGroup;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.group,
    required this.onTap,
    required this.onToggle,
    this.onPinToggle,
    this.onNotify,
    this.showGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    final totalSubtasks = task.subtasks.length;
    final completedSubtasks = task.subtasks
        .where((subtask) => subtask.isCompleted)
        .length;
    final progress = totalSubtasks == 0
        ? 0.0
        : completedSubtasks / totalSubtasks;

    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red.shade400;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange.shade400;
        break;
      case TaskPriority.low:
        priorityColor = Colors.blue.shade400;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                tooltip: task.isCompleted ? 'Mark as pending' : 'Mark as completed',
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 28,
                  color: task.isCompleted ? Colors.green : scheme.primary,
                ),
                onPressed: onToggle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (!task.isCompleted && onPinToggle != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onPinToggle,
                          iconAlignment: IconAlignment.start,
                          icon: Icon(
                            task.isPinned
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                          ),
                          label: Text(task.isPinned ? 'Pinned' : 'Pin'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        if (showGroup && group != null) ...[
                          Text(
                            group!.icon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            group!.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, hh:mm a').format(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (totalSubtasks > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: scheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  priorityColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$completedSubtasks/$totalSubtasks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!task.isCompleted && onNotify != null) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: onNotify,
                        iconAlignment: IconAlignment.start,
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 16,
                        ),
                        label: const Text('Notify'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Semantics(
                  label: 'Priority ${task.priority.name}',
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
