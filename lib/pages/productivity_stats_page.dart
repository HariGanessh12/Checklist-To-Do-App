import 'package:flutter/material.dart';

import '../services/productivity_stats_service.dart';
import '../services/storage_service.dart';

class ProductivityStatsPage extends StatefulWidget {
  const ProductivityStatsPage({super.key});

  @override
  State<ProductivityStatsPage> createState() => _ProductivityStatsPageState();
}

class _ProductivityStatsPageState extends State<ProductivityStatsPage> {
  late ProductivityStats _stats;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final tasks = StorageService.getTasks();
    setState(() {
      _stats = ProductivityStatsService.compute(tasks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1F7),
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
            title: 'Current Streak',
            value:
                '${_stats.currentStreakDays} day${_stats.currentStreakDays == 1 ? '' : 's'}',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFE67E22),
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            title: 'Average Delay',
            value: _formatDelay(_stats.averageDelayHours),
            icon: Icons.schedule_rounded,
            color: const Color(0xFF3A7CA5),
          ),
          const SizedBox(height: 16),
          Text(
            'Average delay is based on completed tasks: completion time minus due time.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
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
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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
