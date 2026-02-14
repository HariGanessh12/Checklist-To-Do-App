import 'package:flutter/material.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../widgets/app_bottom_nav.dart';
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
    allTasks[index] = task.copyWith(isCompleted: false);
    StorageService.saveTasks(allTasks);
    _loadTasks();
  }

  void _clearAll() {
    final allTasks = StorageService.getTasks();
    allTasks.removeWhere((t) => t.isCompleted);
    StorageService.saveTasks(allTasks);
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
      backgroundColor: const Color(0xFFF4F1F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Finished',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_completedTasks.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text(
                        'CLEAR ALL',
                        style: TextStyle(color: Color(0xFFC1332C), fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _completedTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
            alignment: Alignment.center,
            child: const Icon(Icons.emoji_events_rounded, size: 66, color: Color(0xFFF0B43C)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Looking clear!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B4754)),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t finished any tasks yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
