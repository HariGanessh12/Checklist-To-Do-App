import 'package:flutter/material.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/task_detail_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> _tasks = [];
  List<TaskGroup> _groups = [];
  String _selectedGroupId = 'all';

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

  List<Task> get _visibleTasks {
    if (_selectedGroupId == 'all') return _tasks;
    return _tasks.where((t) => t.groupId == _selectedGroupId).toList();
  }

  TaskGroup? _groupForTask(Task task) {
    if (task.groupId == 'individual') return null;
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => _groups.first,
    );
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
    _loadData();
  }

  void _deleteTask(Task task) {
    final allTasks = StorageService.getTasks();
    allTasks.removeWhere((t) => t.id == task.id);
    StorageService.saveTasks(allTasks);
    _loadData();
  }

  void _toggleTaskCompletion(Task task) {
    final allTasks = StorageService.getTasks();
    final idx = allTasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    allTasks[idx] = task.copyWith(isCompleted: true);
    StorageService.saveTasks(allTasks);
    _loadData();
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
        onSave: (savedTask) => _saveTask(savedTask, isNew: task == null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = _visibleTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Text(
                'My Tasks',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            _buildGroupTabs(),
            Expanded(
              child: visibleTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: visibleTasks.length,
                      itemBuilder: (context, index) {
                        final task = visibleTasks[index];
                        return TaskCardWidget(
                          task: task,
                          group: _groupForTask(task),
                          showGroup: _selectedGroupId == 'all',
                          onTap: () => _showTaskDetail(task),
                          onToggle: () => _toggleTaskCompletion(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.tasks),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildGroupTabs() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _buildChip('All', 'all'),
          _buildChip('Individual', 'individual', icon: const Icon(Icons.inbox_outlined, size: 16)),
          ..._groups.map((group) => _buildChip(group.name, group.id, icon: Text(group.icon))),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String id, {Widget? icon}) {
    final selected = _selectedGroupId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: icon,
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF373340),
          ),
        ),
        selectedColor: const Color(0xFF6D54A5),
        backgroundColor: const Color(0xFFF6F4FA),
        side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFD2C9DE)),
        onSelected: (_) => setState(() => _selectedGroupId = id),
      ),
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
            child: const Icon(Icons.auto_awesome_rounded, size: 68, color: Color(0xFFFFB84D)),
          ),
          const SizedBox(height: 32),
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
