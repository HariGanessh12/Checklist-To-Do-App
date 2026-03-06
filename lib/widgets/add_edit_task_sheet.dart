import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';

class AddEditTaskSheet extends StatefulWidget {
  final List<TaskGroup> groups;
  final Function(Task) onSave;
  final Task? taskToEdit;
  final String? initialGroupId;

  const AddEditTaskSheet({
    super.key,
    required this.groups,
    required this.onSave,
    this.taskToEdit,
    this.initialGroupId,
  });

  @override
  State<AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends State<AddEditTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _customRecurrenceController;
  late List<Subtask> _subtasks;
  late List<TextEditingController> _subtaskControllers;
  late TaskPriority _priority;
  late TaskRecurrence _recurrence;
  late bool _streakEnabled;
  late String _selectedGroupId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.taskToEdit?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.taskToEdit?.description ?? '',
    );
    _customRecurrenceController = TextEditingController(
      text: (widget.taskToEdit?.recurrenceIntervalDays ?? 2).toString(),
    );
    _subtasks = List<Subtask>.from(widget.taskToEdit?.subtasks ?? const []);
    _subtaskControllers = _subtasks
        .map((subtask) => TextEditingController(text: subtask.title))
        .toList();
    _priority = widget.taskToEdit?.priority ?? TaskPriority.medium;
    _recurrence = widget.taskToEdit?.recurrence ?? TaskRecurrence.none;
    _streakEnabled = widget.taskToEdit?.streakEnabled ?? false;
    if (_streakEnabled) {
      _recurrence = TaskRecurrence.daily;
    }
    final hasPersonalGroup =
        widget.groups.where((group) => group.id == 'personal').isNotEmpty;
    final hasInitialGroup = widget.initialGroupId != null &&
        widget.groups.any((group) => group.id == widget.initialGroupId);
    _selectedGroupId = widget.taskToEdit?.groupId ??
        (hasInitialGroup
            ? widget.initialGroupId!
            : (hasPersonalGroup ? 'personal' : widget.groups.first.id));
    _selectedDate = widget.taskToEdit?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customRecurrenceController.dispose();
    for (final controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtask() {
    setState(() {
      _subtasks.add(const Subtask(title: ''));
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtasks.removeAt(index);
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final firstAllowedDate = DateTime(now.year - 5, now.month, now.day);
    final initialDate = _selectedDate ?? now;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date == null) return;

    if (!mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
    );

    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _dueDateContextLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (date.isBefore(now)) return 'Overdue';
    if (diff > 1) return 'In $diff days';
    return '${diff.abs()} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSave = _titleController.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.taskToEdit == null ? "Create New Task" : "Edit Task",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: "What needs to be done?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: scheme.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              autofocus: widget.taskToEdit == null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: "Add notes...",
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Subtasks",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_subtasks.isEmpty)
              Text(
                'No subtasks yet.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            if (_subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(_subtasks.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _subtasks[index].isCompleted,
                        onChanged: (value) {
                          setState(() {
                            _subtasks[index] = _subtasks[index].copyWith(
                              isCompleted: value ?? false,
                            );
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _subtaskControllers[index],
                          decoration: const InputDecoration(
                            hintText: 'Subtask title',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            _subtasks[index] = _subtasks[index].copyWith(
                              title: value,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Remove subtask',
                        onPressed: () => _removeSubtask(index),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const Divider(height: 32),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.surfaceContainerHigh,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Due Date & Time",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate == null
                                ? 'No due date'
                                : DateFormat(
                                    'EEEE, MMM d - hh:mm a',
                                  ).format(_selectedDate!),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _selectedDate == null
                                  ? scheme.onSurfaceVariant
                                  : (_selectedDate!.isBefore(DateTime.now())
                                        ? Colors.red
                                        : scheme.onSurface),
                            ),
                          ),
                          if (_selectedDate != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedDate!.isBefore(DateTime.now())
                                    ? Colors.red.withValues(alpha: 0.12)
                                    : scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _dueDateContextLabel(_selectedDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedDate!.isBefore(DateTime.now())
                                      ? Colors.red
                                      : scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        tooltip: 'Clear due date',
                        onPressed: () => setState(() => _selectedDate = null),
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Priority",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(TaskPriority.values.length, (index) {
                final p = TaskPriority.values[index];
                final isSelected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == TaskPriority.values.length - 1 ? 0 : 8,
                    ),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          p.name[0].toUpperCase() + p.name.substring(1),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _priority = p),
                      showCheckmark: false,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<TaskRecurrence>(
              initialValue: _recurrence,
              decoration: InputDecoration(
                labelText: "Repeat",
                prefixIcon: const Icon(Icons.repeat_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskRecurrence.none,
                  child: Text("No Repeat"),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.daily,
                  child: Text("Daily"),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.weekly,
                  child: Text("Weekly"),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.custom,
                  child: Text("Custom (every N days)"),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.monthly,
                  child: Text("Monthly"),
                ),
              ],
              onChanged: _streakEnabled
                  ? null
                  : (v) => setState(() => _recurrence = v!),
            ),
            if (_streakEnabled) ...[
              const SizedBox(height: 6),
              Text(
                'Streak-enabled tasks are automatically set to Daily.',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_recurrence == TaskRecurrence.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customRecurrenceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Repeat every (days)",
                  prefixIcon: const Icon(Icons.calendar_month_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Track Streak For This Task',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Shows a dedicated streak in Productivity Stats.',
              ),
              value: _streakEnabled,
              onChanged: (value) => setState(() {
                _streakEnabled = value;
                if (value) {
                  _recurrence = TaskRecurrence.daily;
                }
              }),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedGroupId,
              decoration: InputDecoration(
                labelText: "Task Group",
                prefixIcon: const Icon(Icons.folder_open_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: [
                ...widget.groups.map(
                  (g) => DropdownMenuItem(
                    value: g.id,
                    child: Text("${g.icon} ${g.name}"),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedGroupId = v!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: canSave
                    ? () {
                        final normalizedSubtasks = <Subtask>[];
                        for (var i = 0; i < _subtasks.length; i++) {
                          final title = _subtaskControllers[i].text.trim();
                          if (title.isEmpty) continue;
                          normalizedSubtasks.add(
                            _subtasks[i].copyWith(title: title),
                          );
                        }
                        int? recurrenceIntervalDays;
                        if (_recurrence == TaskRecurrence.custom) {
                          recurrenceIntervalDays = int.tryParse(
                            _customRecurrenceController.text.trim(),
                          );
                          if (recurrenceIntervalDays == null ||
                              recurrenceIntervalDays < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Custom recurrence must be at least 1 day.',
                                ),
                              ),
                            );
                            return;
                          }
                        } else {
                          recurrenceIntervalDays =
                              widget.taskToEdit?.recurrenceIntervalDays;
                        }
                        final task = Task(
                          id: widget.taskToEdit?.id ?? const Uuid().v4(),
                          groupId: _selectedGroupId,
                          title: _titleController.text.trim(),
                          description: _descriptionController.text.trim(),
                          priority: _priority,
                          dueDate: _selectedDate,
                          isCompleted: widget.taskToEdit?.isCompleted ?? false,
                          isPinned: widget.taskToEdit?.isPinned ?? false,
                          streakEnabled: _streakEnabled,
                          notificationEnabled:
                              widget.taskToEdit?.notificationEnabled ?? true,
                          recurrence: _selectedDate == null
                              ? (_streakEnabled
                                    ? TaskRecurrence.daily
                                    : TaskRecurrence.none)
                              : (_streakEnabled
                                    ? TaskRecurrence.daily
                                    : _recurrence),
                          recurrenceIntervalDays: recurrenceIntervalDays,
                          subtasks: normalizedSubtasks,
                          createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
                        );
                        widget.onSave(task);
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  widget.taskToEdit == null ? "Create Task" : "Save Changes",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

