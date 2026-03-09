import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';

class TaskCardWidget extends StatefulWidget {
  final Task task;
  final TaskGroup? group;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final ValueChanged<int>? onSubtaskToggle;
  final VoidCallback? onPinToggle;
  final VoidCallback? onNotify;
  final bool showGroup;
  final bool showToggle;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.group,
    required this.onTap,
    required this.onToggle,
    this.onSubtaskToggle,
    this.onPinToggle,
    this.onNotify,
    this.showGroup = false,
    this.showToggle = true,
  });

  @override
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  bool _showSubtasks = false;

  String _formatDurationCompact(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final scheme = Theme.of(context).colorScheme;
    final dueDate = task.dueDate;
    final completedAt = task.completedAt;
    final isOverdue =
        !task.isCompleted && dueDate != null && dueDate.isBefore(DateTime.now());
    final totalSubtasks = task.subtasks.length;
    final completedSubtasks = task.subtasks
        .where((subtask) => subtask.isCompleted)
        .length;
    final progress = totalSubtasks == 0 ? 0.0 : completedSubtasks / totalSubtasks;
    final hasSubtasks = totalSubtasks > 0;
    final canToggleSubtasks =
        !task.isCompleted && widget.onSubtaskToggle != null && totalSubtasks > 0;

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
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              if (widget.showToggle)
                hasSubtasks
                    ? IconButton(
                        tooltip:
                            _showSubtasks ? 'Collapse subtasks' : 'Expand subtasks',
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(34, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          _showSubtasks
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 28,
                          color: scheme.primary,
                        ),
                        onPressed: canToggleSubtasks
                            ? () {
                                setState(() {
                                  _showSubtasks = !_showSubtasks;
                                });
                              }
                            : null,
                      )
                    : IconButton(
                        tooltip:
                            task.isCompleted ? 'Mark as pending' : 'Mark as completed',
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(34, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          task.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 28,
                          color: task.isCompleted ? Colors.green : scheme.primary,
                        ),
                        onPressed: widget.onToggle,
                      )
              else
                const SizedBox(width: 34, height: 34),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: task.isCompleted
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (task.isCompleted) ...[
                      if (widget.showGroup && widget.group != null)
                        Row(
                          children: [
                            Text(
                              widget.group!.icon,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.group!.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          ],
                        ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  completedAt == null
                                      ? 'Completed'
                                      : 'Completed - ${DateFormat('MMM d, hh:mm a').format(completedAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dueDate != null && completedAt != null)
                            Builder(
                              builder: (context) {
                                final delta = completedAt.difference(dueDate);
                                if (delta.inMinutes == 0) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'On time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  );
                                }
                                final isLate = !delta.isNegative;
                                final label = isLate ? 'Late' : 'Early';
                                final tone = isLate ? scheme.error : Colors.green;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tone.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$label by ${_formatDurationCompact(delta)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tone,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ] else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.showGroup && widget.group != null) ...[
                            Text(
                              widget.group!.icon,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.group!.name,
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
                            dueDate == null
                                ? 'No due date'
                                : DateFormat('MMM d, hh:mm a').format(dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? scheme.error : scheme.onSurfaceVariant,
                              fontWeight:
                                  isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                            softWrap: true,
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
                      if (_showSubtasks && canToggleSubtasks) ...[
                        const SizedBox(height: 8),
                        ...List.generate(task.subtasks.length, (index) {
                          final subtask = task.subtasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () => widget.onSubtaskToggle!(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      subtask.isCompleted
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 18,
                                      color: subtask.isCompleted
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        subtask.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subtask.isCompleted
                                              ? scheme.onSurfaceVariant
                                              : scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                    if (!task.isCompleted &&
                        (widget.onNotify != null || widget.onPinToggle != null)) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (widget.onPinToggle != null)
                            TextButton.icon(
                              onPressed: widget.onPinToggle,
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
                          if (widget.onNotify != null)
                            TextButton.icon(
                              onPressed: widget.onNotify,
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
