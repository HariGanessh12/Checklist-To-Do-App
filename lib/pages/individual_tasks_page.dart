import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/task_detail_sheet.dart';

class IndividualTasksPage extends StatefulWidget {
  const IndividualTasksPage({super.key});

  @override
  State<IndividualTasksPage> createState() => _IndividualTasksPageState();
}

class _IndividualTasksPageState extends State<IndividualTasksPage> {
  List<Task> _tasks = [];
  List<TaskGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final all = StorageService.getTasks();
    setState(() {
      _groups = StorageService.getGroups();
      _tasks = all.where((t) => !t.isCompleted && t.groupId == 'individual').toList();
    });
  }

  void _saveTask(Task task, {bool isNew = true}) {
    final allTasks = StorageService.getTasks();
    if (isNew) {
      allTasks.insert(0, task);
    } else {
      final idx = allTasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) allTasks[idx] = task;
    }
    StorageService.saveTasks(allTasks);
    NotificationService.scheduleForTask(task);
    _loadData();
  }

  void _deleteTask(Task task) {
    final allTasks = StorageService.getTasks();
    allTasks.removeWhere((t) => t.id == task.id);
    StorageService.saveTasks(allTasks);
    NotificationService.cancelForTask(task.id);
    _loadData();
  }

  void _toggleTaskCompletion(Task task) {
    final allTasks = StorageService.getTasks();
    final idx = allTasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    allTasks[idx] = task.copyWith(isCompleted: true);
    StorageService.saveTasks(allTasks);
    NotificationService.cancelForTask(task.id);
    _loadData();
  }

  Future<void> _notifyTask(Task task) async {
    final count = await NotificationService.scheduleForTask(task);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? 'Scheduled $count reminder${count > 1 ? 's' : ''} for "${task.title}"'
              : 'No future reminder time left for "${task.title}"',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  TaskGroup? _groupForTask(Task task) {
    if (task.groupId == 'individual') return null;
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => _groups.first,
    );
  }

  void _showTaskDetail(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(
        task: task,
        group: _groupForTask(task),
        onEdit: () {
          Navigator.pop(context);
          _showTaskForm(task);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteTask(task);
        },
      ),
    );
  }

  void _showTaskForm([Task? task]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditTaskSheet(
        groups: _groups,
        taskToEdit: task,
        initialGroupId: 'individual',
        onSave: (savedTask) => _saveTask(savedTask, isNew: task == null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'Individual',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: _tasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return TaskCardWidget(
                          task: task,
                          showGroup: false,
                          onTap: () => _showTaskDetail(task),
                          onToggle: () => _toggleTaskCompletion(task),
                          onNotify: () => _notifyTask(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.individual),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.inbox_rounded, size: 58, color: Color(0xFF4C8ED9)),
          ),
          const SizedBox(height: 30),
          const Text(
            'Looking clear!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B4754)),
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks found here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
