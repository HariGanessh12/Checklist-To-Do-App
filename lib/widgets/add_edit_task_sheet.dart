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
  late TaskPriority _priority;
  late TaskRecurrence _recurrence;
  late String _selectedGroupId;
  late DateTime _selectedDate;

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
    _priority = widget.taskToEdit?.priority ?? TaskPriority.medium;
    _recurrence = widget.taskToEdit?.recurrence ?? TaskRecurrence.none;
    _selectedGroupId =
        widget.taskToEdit?.groupId ??
        widget.initialGroupId ??
        widget.groups.first.id;
    _selectedDate =
        widget.taskToEdit?.dueDate ??
        DateTime.now().add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customRecurrenceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date == null) return;

    if (!mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: Colors.grey.shade300,
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
              decoration: const InputDecoration(
                hintText: "What needs to be done?",
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              autofocus: widget.taskToEdit == null,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: "Add notes...",
                icon: Icon(Icons.notes_rounded, size: 20),
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              minLines: 1,
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF6750A4),
              ),
              title: const Text(
                "Due Date & Time",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                DateFormat('EEEE, MMM dd • hh:mm a').format(_selectedDate),
                style: TextStyle(
                  color: _selectedDate.isBefore(DateTime.now())
                      ? Colors.red
                      : Colors.grey.shade700,
                ),
              ),
              onTap: _pickDateTime,
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            const SizedBox(height: 16),
            const Text(
              "Priority",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
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
              }).toList(),
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
              ],
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
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
                const DropdownMenuItem(
                  value: 'individual',
                  child: Text("📥 Individual"),
                ),
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
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) return;
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
                  }
                  final task = Task(
                    id: widget.taskToEdit?.id ?? const Uuid().v4(),
                    groupId: _selectedGroupId,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    priority: _priority,
                    dueDate: _selectedDate,
                    isCompleted: widget.taskToEdit?.isCompleted ?? false,
                    notificationEnabled:
                        widget.taskToEdit?.notificationEnabled ?? true,
                    recurrence: _recurrence,
                    recurrenceIntervalDays: recurrenceIntervalDays,
                    createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
                  );
                  widget.onSave(task);
                  Navigator.pop(context);
                },
                child: Text(
                  widget.taskToEdit == null ? "Create Task" : "Save Changes",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
