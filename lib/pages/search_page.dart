import 'package:flutter/material.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/task_card_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<Task> _allTasks = [];
  List<TaskGroup> _groups = [];
  List<Task> _results = [];

  @override
  void initState() {
    super.initState();
    _allTasks = StorageService.getTasks();
    _groups = StorageService.getGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _results = _allTasks.where((t) {
        return t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q);
      }).toList();
    });
  }

  TaskGroup? _groupForTask(Task task) {
    if (task.groupId == 'individual') return null;
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == task.groupId,
      orElse: () => _groups.first,
    );
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

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'Find Tasks',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'What are you looking for?',
                  hintStyle: const TextStyle(fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(Icons.search_rounded, size: 28),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF6D54A5), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF6D54A5), width: 2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? _buildEmptyState(hasQuery)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final task = _results[index];
                        return TaskCardWidget(
                          task: task,
                          group: _groupForTask(task),
                          showGroup: true,
                          onTap: () {},
                          onToggle: () {},
                          onNotify: task.isCompleted ? null : () => _notifyTask(task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.search),
    );
  }

  Widget _buildEmptyState(bool hasQuery) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
            alignment: Alignment.center,
            child: Icon(
              hasQuery ? Icons.search_rounded : Icons.auto_awesome_rounded,
              size: 66,
              color: hasQuery ? const Color(0xFF6D54A5) : const Color(0xFFFFB84D),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Looking clear!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4B4754)),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery ? 'No tasks match your search.' : 'No tasks found here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
