import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
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
            trailing: Text(
              task.priority.name.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
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
          ),
        );
      },
    );
  }
}
