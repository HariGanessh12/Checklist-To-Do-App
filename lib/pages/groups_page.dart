import 'package:flutter/material.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../widgets/add_edit_group_sheet.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_page_header.dart';
import 'group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<TaskGroup> _groups = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _groups = StorageService.getGroups();
      _tasks = StorageService.getTasks();
    });
  }

  int _countTasksInGroup(String groupId) {
    return _tasks.where((t) => t.groupId == groupId && !t.isCompleted).length;
  }

  void _showGroupSheet([TaskGroup? group]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditGroupSheet(
        groupToEdit: group,
        onSave: (saved) {
          final list = StorageService.getGroups();
          final index = list.indexWhere((g) => g.id == saved.id);
          if (index == -1) {
            list.add(saved);
          } else {
            list[index] = saved;
          }
          StorageService.saveGroups(list);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Task Groups',
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemCount: _groups.length + 1,
                itemBuilder: (context, index) {
                  if (index == _groups.length) return _buildNewGroupCard();
                  final group = _groups[index];
                  return _buildGroupCard(group);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.groups),
    );
  }

  Widget _buildGroupCard(TaskGroup group) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 62,
              decoration: BoxDecoration(
                color: Color(group.colorValue).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(group.icon, style: const TextStyle(fontSize: 30)),
            ),
            const Spacer(),
            Text(
              group.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${_countTasksInGroup(group.id)} TASKS',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewGroupCard() {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showGroupSheet(),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: scheme.outline,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.add_rounded, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Text(
              'NEW GROUP',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
