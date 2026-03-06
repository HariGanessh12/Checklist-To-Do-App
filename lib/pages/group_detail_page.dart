import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';
import '../services/task_completion_service.dart';
import '../widgets/add_edit_task_sheet.dart';
import '../widgets/task_card_widget.dart';
import '../widgets/task_detail_sheet.dart';

class GroupDetailPage extends StatefulWidget {
  final TaskGroup group;
  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Task> _groupTasks = [];
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationsEnabled = StorageService.getAnimationsEnabled();
    StorageService.animationsEnabledNotifier.addListener(
      _onAnimationSettingChanged,
    );
    _loadData();
  }

  @override
  void dispose() {
    StorageService.animationsEnabledNotifier.removeListener(
      _onAnimationSettingChanged,
    );
    super.dispose();
  }

  void _onAnimationSettingChanged() {
    if (!mounted) return;
    setState(() {
      _animationsEnabled = StorageService.animationsEnabledNotifier.value;
    });
  }

  void _loadData() {
    setState(() {
      final allTasks = StorageService.getTasks();
      _groupTasks =
          allTasks
              .where((t) => t.groupId == widget.group.id && !t.isCompleted)
              .toList()
            ..sort(_comparePinnedThenDueDate);
    });
  }

  int _comparePinnedThenDueDate(Task a, Task b) {
    if (a.isPinned != b.isPinned) {
      return a.isPinned ? -1 : 1;
    }
    return a.dueDate.compareTo(b.dueDate);
  }

  void _saveTask(Task task, {bool isNew = true}) {
    final allTasks = StorageService.getTasks();
    setState(() {
      if (isNew) {
        allTasks.insert(0, task);
        _groupTasks.insert(0, task);
        _groupTasks.sort(_comparePinnedThenDueDate);
        final insertIndex = _groupTasks.indexWhere(
          (entry) => entry.id == task.id,
        );
        if (insertIndex != -1) {
          _listKey.currentState?.insertItem(
            insertIndex,
            duration: _animationsEnabled
                ? const Duration(milliseconds: 300)
                : Duration.zero,
          );
        }
      } else {
        final index = allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) allTasks[index] = task;
        final gIndex = _groupTasks.indexWhere((t) => t.id == task.id);
        if (gIndex != -1) _groupTasks[gIndex] = task;
        _groupTasks.sort(_comparePinnedThenDueDate);
      }
    });
    StorageService.saveTasks(allTasks);
    NotificationService.scheduleForTask(task);
  }

  void _deleteTask(Task task) {
    final index = _groupTasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final removedTask = _groupTasks.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedItem(removedTask, animation),
      duration: _animationsEnabled
          ? const Duration(milliseconds: 300)
          : Duration.zero,
    );

    final allTasks = StorageService.getTasks();
    allTasks.removeWhere((t) => t.id == task.id);
    StorageService.saveTasks(allTasks);
    NotificationService.cancelForTask(task.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () {
            final restored = StorageService.getTasks();
            restored.insert(0, task);
            StorageService.saveTasks(restored);
            NotificationService.scheduleForTask(task);
            _loadData();
          },
        ),
      ),
    );
  }

  void _toggleTask(Task task) {
    if (!TaskCompletionService.canCompleteNow(task)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TaskCompletionService.blockedMessage(task))),
      );
      return;
    }
    final index = _groupTasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final updated = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    final nextTask = RecurrenceService.nextOccurrenceFor(task);
    setState(() {
      _groupTasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedItem(updated, animation),
        duration: _animationsEnabled
            ? const Duration(milliseconds: 300)
            : Duration.zero,
      );
      if (nextTask != null && nextTask.groupId == widget.group.id) {
        _groupTasks.insert(0, nextTask);
        _listKey.currentState?.insertItem(
          0,
          duration: _animationsEnabled
              ? const Duration(milliseconds: 300)
              : Duration.zero,
        );
      }
    });

    final allTasks = StorageService.getTasks();
    final globalIdx = allTasks.indexWhere((t) => t.id == task.id);
    if (globalIdx != -1) allTasks[globalIdx] = updated;
    if (nextTask != null) {
      allTasks.insert(0, nextTask);
    }
    StorageService.saveTasks(allTasks);
    NotificationService.cancelForTask(task.id);
    if (nextTask != null) {
      NotificationService.scheduleForTask(nextTask);
    }
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

  void _togglePin(Task task) {
    final allTasks = StorageService.getTasks();
    final idx = allTasks.indexWhere((entry) => entry.id == task.id);
    if (idx == -1) return;
    final updated = task.copyWith(isPinned: !task.isPinned);
    allTasks[idx] = updated;
    StorageService.saveTasks(allTasks);
    _loadData();
  }

  Widget _buildAnimatedItem(Task task, Animation<double> animation) {
    final item = Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TaskCardWidget(
        task: task,
        group: widget.group,
        onTap: () => _showTaskDetail(task),
        onToggle: () => _toggleTask(task),
        onPinToggle: () => _togglePin(task),
        onNotify: () => _notifyTask(task),
      ),
    );
    if (!_animationsEnabled) return item;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: item,
      ),
    );
  }

  void _showTaskDetail(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(
        task: task,
        group: widget.group,
        onEdit: () {
          Navigator.pop(context);
          _showTaskSheet(task);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteTask(task);
        },
      ),
    );
  }

  void _showTaskSheet([Task? task]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditTaskSheet(
        groups: StorageService.getGroups(),
        taskToEdit: task,
        onSave: (saved) => _saveTask(saved, isNew: task == null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.group.icon),
            const SizedBox(width: 12),
            Text(
              widget.group.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _groupTasks.isEmpty
          ? _buildEmptyState()
          : AnimatedList(
              key: _listKey,
              initialItemCount: _groupTasks.length,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemBuilder: (context, index, animation) {
                return _buildAnimatedItem(_groupTasks[index], animation);
              },
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showTaskSheet(),
        child: const Icon(Icons.add_task_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            "Clear skies in ${widget.group.name}",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No pending tasks here",
            style: TextStyle(color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}
