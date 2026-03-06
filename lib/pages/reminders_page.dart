import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_group_model.dart';
import '../models/task_model.dart';
import 'reminder_presets_page.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Task> _tasks = [];
  List<TaskGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _tasks = StorageService.getTasks().where((t) => !t.isCompleted).toList();
      _groups = StorageService.getGroups();
    });
  }

  TaskGroup? _groupForTask(Task task) {
    if (task.groupId == 'individual') return null;
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => _groups.first,
    );
  }

  Future<void> _toggleReminder(Task task, bool enabled) async {
    final updated = task.copyWith(notificationEnabled: enabled);
    final allTasks = StorageService.getTasks();
    final index = allTasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    allTasks[index] = updated;
    await StorageService.saveTasks(allTasks);

    if (enabled) {
      await NotificationService.scheduleForTask(updated);
    } else {
      await NotificationService.cancelForTask(updated.id);
    }

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final enabledTasks = _tasks.where((t) => t.notificationEnabled).toList();
    final disabledTasks = _tasks.where((t) => !t.notificationEnabled).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Reminders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Reminder Presets',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReminderPresetsPage(),
                  ),
                );
                _loadData();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reminders On'),
              Tab(text: 'No Reminders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(enabledTasks, enabledTab: true),
            _buildList(disabledTasks, enabledTab: false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Task> tasks, {required bool enabledTab}) {
    final scheme = Theme.of(context).colorScheme;
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          enabledTab
              ? 'No tasks with reminders enabled.'
              : 'No tasks without reminders.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final group = _groupForTask(task);
        final upcoming = NotificationService.upcomingReminderTimes(task);
        final nextAlarm = upcoming.isNotEmpty
            ? DateFormat('MMM d, hh:mm a').format(upcoming.first)
            : null;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: task.notificationEnabled,
                      onChanged: (value) => _toggleReminder(task, value),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${DateFormat('EEE, MMM d - hh:mm a').format(task.dueDate)}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  group == null
                      ? 'Group: Individual'
                      : 'Group: ${group.icon} ${group.name}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  'Priority: ${task.priority.name.toUpperCase()}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  _recurrenceLabel(task),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  task.notificationEnabled
                      ? (nextAlarm == null
                            ? 'No future reminders left'
                            : 'Next alarm: $nextAlarm (${upcoming.length} pending)')
                      : 'Reminders are turned off',
                  style: TextStyle(
                    color: task.notificationEnabled
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _recurrenceLabel(Task task) {
    switch (task.recurrence) {
      case TaskRecurrence.none:
        return 'Repeat: None';
      case TaskRecurrence.daily:
        return 'Repeat: Daily';
      case TaskRecurrence.weekly:
        return 'Repeat: Weekly';
      case TaskRecurrence.custom:
        final days = task.recurrenceIntervalDays ?? 1;
        return 'Repeat: Every $days day${days == 1 ? '' : 's'}';
      case TaskRecurrence.monthly:
        return 'Repeat: Monthly';
    }
  }
}
