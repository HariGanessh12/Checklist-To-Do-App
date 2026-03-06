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
      _completedTasks = allTasks.where((t) => t.isCompleted).toList();
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

  void _clearAll() {
    final allTasks = StorageService.getTasks();
    final completedIds = allTasks
        .where((t) => t.isCompleted)
        .map((t) => t.id)
        .toList();
    allTasks.removeWhere((t) => t.isCompleted);
    StorageService.saveTasks(allTasks);
    for (final taskId in completedIds) {
      NotificationService.cancelForTask(taskId);
    }
    _loadTasks();
  }

  TaskGroup? _groupForTask(Task task) {
    if (task.groupId == 'individual') return null;
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => _groups.first,
    );
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
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      itemCount: _completedTasks.length,
                      itemBuilder: (context, index) {
                        final task = _completedTasks[index];
                        return TaskCardWidget(
                          task: task,
                          group: _groupForTask(task),
                          showGroup: true,
                          onTap: () {},
                          onToggle: () => _restoreTask(task),
                        );
                      },
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
