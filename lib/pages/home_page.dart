import 'package:flutter/material.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import 'calendar_page.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';
import '../services/task_completion_service.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_page_header.dart';
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
  TaskTimeFilter _selectedTimeFilter = TaskTimeFilter.today;

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

  List<Task> get _groupFilteredTasks {
    if (_selectedGroupId == 'all') return _tasks;
    return _tasks.where((t) => t.groupId == _selectedGroupId).toList();
  }

  List<Task> get _visibleTasks {
    final source = _groupFilteredTasks;
    return source.where(_matchesTimeFilter).toList()
      ..sort(_comparePinnedThenDueDate);
  }

  int _comparePinnedThenDueDate(Task a, Task b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  bool _matchesTimeFilter(Task task) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    switch (_selectedTimeFilter) {
      case TaskTimeFilter.today:
        if (task.dueDate == null) return true;
        return !task.dueDate!.isBefore(now) &&
            !task.dueDate!.isBefore(todayStart) &&
            task.dueDate!.isBefore(tomorrowStart);
      case TaskTimeFilter.upcoming:
        if (task.dueDate == null) return false;
        return !task.dueDate!.isBefore(tomorrowStart);
      case TaskTimeFilter.overdue:
        if (task.dueDate == null) return false;
        return task.dueDate!.isBefore(now);
    }
  }

  int _countForFilter(TaskTimeFilter filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final source = _groupFilteredTasks;

    switch (filter) {
      case TaskTimeFilter.today:
        return source
            .where(
              (task) =>
                  task.dueDate == null ||
                  (!task.dueDate!.isBefore(now) &&
                      !task.dueDate!.isBefore(todayStart) &&
                      task.dueDate!.isBefore(tomorrowStart)),
            )
            .length;
      case TaskTimeFilter.upcoming:
        return source
            .where(
              (task) =>
                  task.dueDate != null &&
                  !task.dueDate!.isBefore(tomorrowStart),
            )
            .length;
      case TaskTimeFilter.overdue:
        return source
            .where((task) => task.dueDate != null && task.dueDate!.isBefore(now))
            .length;
    }
  }

  TaskGroup? _groupForTask(Task task) {
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
    if (!TaskCompletionService.canCompleteNow(task)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TaskCompletionService.blockedMessage(task))),
      );
      return;
    }
    final allTasks = StorageService.getTasks();
    final idx = allTasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    allTasks[idx] = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    final nextTask = RecurrenceService.nextOccurrenceFor(task);
    if (nextTask != null) {
      allTasks.insert(0, nextTask);
    }
    StorageService.saveTasks(allTasks);
    NotificationService.cancelForTask(task.id);
    if (nextTask != null) {
      NotificationService.scheduleForTask(nextTask);
    }
    _loadData();
  }

  void _togglePin(Task task) {
    final allTasks = StorageService.getTasks();
    final idx = allTasks.indexWhere((entry) => entry.id == task.id);
    if (idx == -1) return;
    allTasks[idx] = task.copyWith(isPinned: !task.isPinned);
    StorageService.saveTasks(allTasks);
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
      ),
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
        onSave: (savedTask) => _saveTask(savedTask, isNew: task == null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = _visibleTasks;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'My Tasks',
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              trailing: IconButton(
                tooltip: 'Calendar View',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CalendarPage()),
                  );
                },
                icon: const Icon(Icons.calendar_month_rounded),
              ),
            ),
            _buildGroupTabs(),
            _buildTimeFilterTabs(),
            Expanded(
              child: visibleTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      itemCount: visibleTasks.length,
                      itemBuilder: (context, index) {
                        final task = visibleTasks[index];
                        return TaskCardWidget(
                          task: task,
                          group: _groupForTask(task),
                          showGroup: _selectedGroupId == 'all',
                          onTap: () => _showTaskDetail(task),
                          onToggle: () => _toggleTaskCompletion(task),
                          onPinToggle: () => _togglePin(task),
                          onNotify: () => _notifyTask(task),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('All', 'all'),
          ..._groups.map(
            (group) => _buildChip(group.name, group.id, icon: Text(group.icon)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String id, {Widget? icon}) {
    final scheme = Theme.of(context).colorScheme;
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
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
        selectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(
          color: selected ? Colors.transparent : scheme.outlineVariant,
        ),
        onSelected: (_) => setState(() => _selectedGroupId = id),
      ),
    );
  }

  Widget _buildTimeFilterTabs() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildTimeFilterChip(
            label: 'Today',
            count: _countForFilter(TaskTimeFilter.today),
            filter: TaskTimeFilter.today,
          ),
          _buildTimeFilterChip(
            label: 'Upcoming',
            count: _countForFilter(TaskTimeFilter.upcoming),
            filter: TaskTimeFilter.upcoming,
          ),
          _buildTimeFilterChip(
            label: 'Overdue',
            count: _countForFilter(TaskTimeFilter.overdue),
            filter: TaskTimeFilter.overdue,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip({
    required String label,
    required int count,
    required TaskTimeFilter filter,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedTimeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Text(
          '$label ($count)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
        selectedColor: scheme.tertiary,
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(
          color: selected ? Colors.transparent : scheme.outlineVariant,
        ),
        onSelected: (_) => setState(() => _selectedTimeFilter = filter),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.auto_awesome_rounded,
      title: 'Looking clear!',
      message: 'No tasks found here.',
      iconSize: 68,
    );
  }
}

enum TaskTimeFilter { today, upcoming, overdue }
