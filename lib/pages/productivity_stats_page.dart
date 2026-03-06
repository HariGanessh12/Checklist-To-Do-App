import 'package:flutter/material.dart';

import '../models/task_group_model.dart';
import '../services/productivity_stats_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_surface_card.dart';

class ProductivityStatsPage extends StatefulWidget {
  const ProductivityStatsPage({super.key});

  @override
  State<ProductivityStatsPage> createState() => _ProductivityStatsPageState();
}

class _ProductivityStatsPageState extends State<ProductivityStatsPage> {
  late ProductivityStats _stats;
  List<TaskGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final tasks = StorageService.getTasks();
    setState(() {
      _stats = ProductivityStatsService.compute(tasks);
      _groups = StorageService.getGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Productivity Stats')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildStatCard(
            title: 'Completion Rate',
            value:
                '${(_stats.completionRate * 100).toStringAsFixed(1)}% (${_stats.completedTasks}/${_stats.totalTasks})',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF2D8A5F),
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            title: 'Average Delay',
            value: _formatDelay(_stats.averageDelayHours),
            icon: Icons.schedule_rounded,
            color: const Color(0xFF3A7CA5),
          ),
          const SizedBox(height: 12),
          Text(
            'Task Streaks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (_stats.taskStreaks.isEmpty)
            AppSurfaceCard(
              showShadow: false,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(16),
              child: Text(
                'No task-specific streaks yet. Enable "Track Streak For This Task" while creating or editing a task.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          if (_stats.taskStreaks.isNotEmpty)
            ..._stats.taskStreaks.map(_buildTaskStreakTile),
          const SizedBox(height: 16),
          Text(
            'Average delay is based on completed tasks: completion time minus due time. Task streaks are shown only for tasks with streak tracking enabled.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStreakTile(TaskStreakStat stat) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
      showShadow: false,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE67E22).withValues(alpha: 0.15),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFE67E22),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _groupLabel(stat.groupId),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${stat.streakDays}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.local_fire_department_outlined,
            size: 18,
            color: Color(0xFFE67E22),
          ),
        ],
      ),
    );
  }

  String _groupLabel(String groupId) {
    if (groupId == 'individual') return 'Individual';
    TaskGroup? group;
    for (final entry in _groups) {
      if (entry.id == groupId) {
        group = entry;
        break;
      }
    }
    if (group == null) return 'Group';
    return '${group.icon} ${group.name}';
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      showShadow: false,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDelay(double hours) {
    final abs = hours.abs();
    final label = '${abs.toStringAsFixed(1)}h';
    if (hours > 0) return '$label late';
    if (hours < 0) return '$label early';
    return '0.0h on time';
  }
}
