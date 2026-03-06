import 'package:flutter/material.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_page_header.dart';
import '../widgets/task_card_widget.dart';

class CompletedTasksPage extends StatefulWidget {
  const CompletedTasksPage({super.key});

  @override
  State<CompletedTasksPage> createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends State<CompletedTasksPage> {
  static const Duration _restoreWindow = Duration(hours: 6);
  List<Task> _completedTasks = [];
  List<TaskGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final allTasks = StorageService.getTasks();
    setState(() {
      _groups = StorageService.getGroups();
      _completedTasks = allTasks.where((t) => t.isCompleted).toList()
        ..sort((a, b) {
          final aTime = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
    });
  }

  void _restoreTask(Task task) {
    final allTasks = StorageService.getTasks();
    final index = allTasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    final restoredTask = task.copyWith(
      isCompleted: false,
      clearCompletedAt: true,
    );
    allTasks[index] = restoredTask;
    StorageService.saveTasks(allTasks);
    NotificationService.scheduleForTask(restoredTask);
    _loadTasks();
  }

  Future<void> _clearAll() async {
    final allTasks = StorageService.getTasks();
    final removedTasks = allTasks.where((t) => t.isCompleted).toList();
    final completedIds = allTasks
        .where((t) => t.isCompleted)
        .map((t) => t.id)
        .toList();
    allTasks.removeWhere((t) => t.isCompleted);
    await StorageService.addTasksToRecycleBin(removedTasks);
    await StorageService.saveTasks(allTasks);
    for (final taskId in completedIds) {
      await NotificationService.cancelForTask(taskId);
    }
    _loadTasks();
  }

  TaskGroup? _groupForTask(Task task) {
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => _groups.first,
    );
  }

  bool _canRestore(Task task, {DateTime? now}) {
    final completedAt = task.completedAt;
    if (completedAt == null) return false;
    final current = now ?? DateTime.now();
    return current.difference(completedAt) <= _restoreWindow;
  }

  String _sectionLabelFor(DateTime completedAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(completedAt.year, completedAt.month, completedAt.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${completedAt.day}/${completedAt.month}/${completedAt.year}';
  }

  List<Widget> _buildCompletedSections() {
    final sections = <String, List<Task>>{};
    final orderedLabels = <String>[];
    for (final task in _completedTasks) {
      final completedAt = task.completedAt;
      final label = completedAt == null ? 'Earlier' : _sectionLabelFor(completedAt);
      if (!sections.containsKey(label)) {
        sections[label] = <Task>[];
        orderedLabels.add(label);
      }
      sections[label]!.add(task);
    }

    final widgets = <Widget>[];
    for (final label in orderedLabels) {
      final tasks = sections[label]!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
      for (final task in tasks) {
        final canRestore = _canRestore(task);
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TaskCardWidget(
              task: task,
              group: _groupForTask(task),
              showGroup: true,
              onTap: () {},
              showToggle: canRestore,
              onToggle: canRestore ? () => _restoreTask(task) : () {},
            ),
          ),
        );
      }
    }
    widgets.add(const SizedBox(height: 110));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Finished',
              trailing: _completedTasks.isNotEmpty
                  ? TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        'CLEAR ALL',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: _completedTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      children: _buildCompletedSections(),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.done),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.emoji_events_rounded,
      title: 'Looking clear!',
      message: 'You haven\'t finished any tasks yet.',
      accentColor: Theme.of(context).colorScheme.tertiary,
    );
  }
}
