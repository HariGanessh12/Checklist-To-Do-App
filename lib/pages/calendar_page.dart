import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';

enum CalendarViewMode { month, week }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<Task> _tasks = [];
  List<TaskGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _tasks = StorageService.getTasks()
          .where((task) => !task.isCompleted)
          .toList();
      _groups = StorageService.getGroups();
    });
  }

  TaskGroup? _groupForTask(Task task) {
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (group) => group.id == task.groupId,
      orElse: () => _groups.first,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

  int _taskCountForDate(DateTime date) {
    final day = _dateOnly(date);
    return _tasks
        .where((task) => task.dueDate != null && _dateOnly(task.dueDate!) == day)
        .length;
  }

  List<Task> _tasksForSelectedDate() {
    final day = _dateOnly(_selectedDate);
    final result = _tasks
        .where((task) => task.dueDate != null && _dateOnly(task.dueDate!) == day)
        .toList();
    result.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return result;
  }

  DateTime _startOfWeek(DateTime date) {
    final day = _dateOnly(date);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _tasksForSelectedDate();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<CalendarViewMode>(
              segments: const [
                ButtonSegment(
                  value: CalendarViewMode.month,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_month_rounded),
                ),
                ButtonSegment(
                  value: CalendarViewMode.week,
                  label: Text('Week'),
                  icon: Icon(Icons.view_week_rounded),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _viewMode = selection.first;
                });
              },
            ),
          ),
          if (_viewMode == CalendarViewMode.month) _buildMonthView(),
          if (_viewMode == CalendarViewMode.week) _buildWeekView(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedTasks.length} task${selectedTasks.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks due on this day.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: selectedTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      final group = _groupForTask(task);
                      return _buildTaskTile(task, group);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    final scheme = Theme.of(context).colorScheme;
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final offset = (monthStart.weekday - DateTime.monday + 7) % 7;
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
              _WeekdayLabel('Sun'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayNumber,
              );
              return _buildDayCell(day);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final scheme = Theme.of(context).colorScheme;
    final start = _startOfWeek(_selectedDate);
    final weekDays = List.generate(
      7,
      (index) => start.add(Duration(days: index)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 7),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${DateFormat('MMM d').format(weekDays.first)} - ${DateFormat('MMM d').format(weekDays.last)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: weekDays
                .map(
                  (day) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildDayCell(day, compact: true),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool compact = false}) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _isSameDay(day, _selectedDate);
    final isToday = _isSameDay(day, DateTime.now());
    final taskCount = _taskCountForDate(day);
    final label = compact ? DateFormat('E').format(day) : '';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _selectedDate = day;
          _focusedMonth = DateTime(day.year, day.month);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? scheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (compact)
              Text(
                label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            if (taskCount > 0)
              Container(
                width: compact ? 16 : 18,
                height: compact ? 16 : 18,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$taskCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(Task task, TaskGroup? group) {
    final scheme = Theme.of(context).colorScheme;
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red.shade400;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange.shade400;
        break;
      case TaskPriority.low:
        priorityColor = Colors.blue.shade400;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 44,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('hh:mm a').format(task.dueDate!)}  -  ${group == null ? 'Individual' : '${group.icon} ${group.name}'}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            task.priority.name.toUpperCase(),
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
