import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_empty_state.dart';

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  List<Task> _deletedTasks = [];
  List<TaskGroup> _deletedGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _deletedTasks = StorageService.getRecycleBinTasks();
      _deletedGroups = StorageService.getRecycleBinGroups();
    });
  }

  Future<void> _restoreTask(Task task) async {
    final groups = StorageService.getGroups();
    if (groups.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No task groups available to restore into.')),
      );
      return;
    }

    final originalGroupExists = groups.any((group) => group.id == task.groupId);
    String selectedGroupId = originalGroupExists ? task.groupId : groups.first.id;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Restore task?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Restore "${task.title}"?'),
                if (!originalGroupExists) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Original group was deleted. Choose a group to restore this task:',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGroupId,
                    items: groups
                        .map(
                          (group) => DropdownMenuItem<String>(
                            value: group.id,
                            child: Text('${group.icon} ${group.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedGroupId = value);
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('RESTORE'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    final allTasks = StorageService.getTasks();
    final restored = originalGroupExists
        ? task
        : task.copyWith(groupId: selectedGroupId);
    final existingIndex = allTasks.indexWhere((entry) => entry.id == restored.id);
    if (existingIndex == -1) {
      allTasks.insert(0, restored);
    } else {
      allTasks[existingIndex] = restored;
    }

    await StorageService.saveTasks(allTasks);
    await StorageService.removeTasksFromRecycleBinById([task.id]);
    if (!restored.isCompleted && restored.notificationEnabled) {
      await NotificationService.scheduleForTask(restored);
    }
    _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored "${restored.title}".')),
    );
  }

  Future<void> _restoreGroup(TaskGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore group?'),
        content: Text('Restore "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final groups = StorageService.getGroups();
    final exists = groups.any((entry) => entry.id == group.id);
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A group with id "${group.id}" already exists. Delete it first to restore this one.',
          ),
        ),
      );
      return;
    }

    groups.add(group);
    await StorageService.saveGroups(groups);
    await StorageService.removeGroupsFromRecycleBinById([group.id]);
    _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored group "${group.name}".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('Recycle Bin'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Tasks (${_deletedTasks.length})'),
              Tab(text: 'Task Groups (${_deletedGroups.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTasksTab(),
            _buildGroupsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_deletedTasks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.delete_outline_rounded,
        title: 'No deleted tasks',
        message: 'Manually deleted tasks will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _deletedTasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = _deletedTasks[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          elevation: 0,
          child: ListTile(
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              task.dueDate == null
                  ? 'No due date'
                  : 'Due ${DateFormat('MMM d, hh:mm a').format(task.dueDate!)}',
            ),
            onTap: () => _restoreTask(task),
            trailing: Wrap(
              spacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  task.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Restore task',
                  onPressed: () => _restoreTask(task),
                  icon: const Icon(Icons.restore_from_trash_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    if (_deletedGroups.isEmpty) {
      return const AppEmptyState(
        icon: Icons.folder_delete_outlined,
        title: 'No deleted groups',
        message: 'Deleted task groups will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _deletedGroups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = _deletedGroups[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(group.colorValue).withValues(alpha: 0.15),
              child: Text(group.icon),
            ),
            title: Text(group.name),
            onTap: () => _restoreGroup(group),
            trailing: IconButton(
              tooltip: 'Restore group',
              onPressed: () => _restoreGroup(group),
              icon: const Icon(Icons.restore_from_trash_rounded),
            ),
          ),
        );
      },
    );
  }
}
