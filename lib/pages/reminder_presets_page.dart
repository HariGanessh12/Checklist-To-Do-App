import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/reminder_preset_service.dart';
import '../services/storage_service.dart';

class ReminderPresetsPage extends StatefulWidget {
  const ReminderPresetsPage({super.key});

  @override
  State<ReminderPresetsPage> createState() => _ReminderPresetsPageState();
}

class _ReminderPresetsPageState extends State<ReminderPresetsPage> {
  late Map<TaskPriority, List<int>> _presets;

  @override
  void initState() {
    super.initState();
    _presets = ReminderPresetService.getAllPresetMinutes();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Reminder Presets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSection(TaskPriority.high),
          const SizedBox(height: 12),
          _buildSection(TaskPriority.medium),
          const SizedBox(height: 12),
          _buildSection(TaskPriority.low),
          const SizedBox(height: 16),
          Text(
            'Tip: negative = before due time, 0 = at due time, positive = after due time.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(TaskPriority priority) {
    final scheme = Theme.of(context).colorScheme;
    final list = _presets[priority] ?? <int>[];
    final title =
        '${priority.name[0].toUpperCase()}${priority.name.substring(1)} Priority';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _addOffset(priority),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (list.isEmpty)
            Text(
              'No reminders configured.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          if (list.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map(
                    (value) => Chip(
                      label: Text(_formatOffset(value)),
                      onDeleted: () => _removeOffset(priority, value),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _addOffset(TaskPriority priority) async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder Offset'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Offset in minutes',
              hintText: 'Examples: -60, 0, 15',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                Navigator.pop(context, parsed);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    final updated = List<int>.from(_presets[priority] ?? <int>[])..add(value);
    await ReminderPresetService.savePriorityPreset(priority, updated);
    await _rescheduleActiveTasks();
    setState(() {
      _presets = ReminderPresetService.getAllPresetMinutes();
    });
  }

  Future<void> _removeOffset(TaskPriority priority, int value) async {
    final updated = List<int>.from(_presets[priority] ?? <int>[])
      ..removeWhere((entry) => entry == value);
    await ReminderPresetService.savePriorityPreset(priority, updated);
    await _rescheduleActiveTasks();
    setState(() {
      _presets = ReminderPresetService.getAllPresetMinutes();
    });
  }

  Future<void> _rescheduleActiveTasks() async {
    final tasks = StorageService.getTasks();
    for (final task in tasks) {
      if (task.isCompleted) continue;
      if (task.notificationEnabled) {
        await NotificationService.scheduleForTask(task);
      } else {
        await NotificationService.cancelForTask(task.id);
      }
    }
  }

  String _formatOffset(int minutes) {
    if (minutes == 0) return 'At due time';
    final absMinutes = minutes.abs();
    if (absMinutes % 1440 == 0) {
      final days = absMinutes ~/ 1440;
      return minutes < 0
          ? '$days day${days == 1 ? '' : 's'} before'
          : '$days day${days == 1 ? '' : 's'} after';
    }
    if (absMinutes % 60 == 0) {
      final hours = absMinutes ~/ 60;
      return minutes < 0
          ? '$hours hour${hours == 1 ? '' : 's'} before'
          : '$hours hour${hours == 1 ? '' : 's'} after';
    }
    return minutes < 0 ? '$absMinutes min before' : '$absMinutes min after';
  }
}
