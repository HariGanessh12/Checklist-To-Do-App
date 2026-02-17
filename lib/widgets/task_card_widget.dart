
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final TaskGroup? group;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback? onNotify;
  final bool showGroup;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.group,
    required this.onTap,
    required this.onToggle,
    this.onNotify,
    this.showGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high: priorityColor = Colors.red.shade400; break;
      case TaskPriority.medium: priorityColor = Colors.orange.shade400; break;
      case TaskPriority.low: priorityColor = Colors.blue.shade400; break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  task.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 28,
                  color: task.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
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
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (showGroup && group != null) ...[
                          Text(group!.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            group!.name,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isOverdue ? Colors.red : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, HH:mm').format(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey.shade500,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (!task.isCompleted && onNotify != null) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: onNotify,
                        icon: const Icon(Icons.notifications_active_outlined, size: 16),
                        label: const Text('Notify'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: const Size(0, 28),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priority.name.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
