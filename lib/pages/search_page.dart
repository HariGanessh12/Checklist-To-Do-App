import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_group_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_page_header.dart';
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
  DateTime? _startDate;
  DateTime? _endDate;
  String _groupFilter = 'all';
  bool? _streakFilter;
  bool? _completionFilter;
  Set<TaskPriority> _priorityFilters = <TaskPriority>{};
  Set<TaskRecurrence> _recurrenceFilters = <TaskRecurrence>{};

  @override
  void initState() {
    super.initState();
    _allTasks = StorageService.getTasks();
    _groups = StorageService.getGroups();
    _allTasks.sort(_compareByDueDateAscending);
    _applySearchAndFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _applySearchAndFilters();
  }

  int _compareByDueDateAscending(Task a, Task b) {
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    int byDueDate;
    if (aDue == null && bDue == null) {
      byDueDate = 0;
    } else if (aDue == null) {
      byDueDate = 1;
    } else if (bDue == null) {
      byDueDate = -1;
    } else {
      byDueDate = aDue.compareTo(bDue);
    }
    if (byDueDate != 0) return byDueDate;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  TaskGroup? _groupForTask(Task task) {
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
      ),
    );
  }

  void _togglePin(Task task) {
    final allTasks = StorageService.getTasks();
    final idx = allTasks.indexWhere((entry) => entry.id == task.id);
    if (idx == -1) return;
    allTasks[idx] = task.copyWith(isPinned: !task.isPinned);
    StorageService.saveTasks(allTasks);
    _allTasks = allTasks..sort(_compareByDueDateAscending);
    _applySearchAndFilters();
  }

  void _applySearchAndFilters() {
    final q = _searchController.text.trim().toLowerCase();
    final start = _startDate;
    final end = _endDate;

    final filtered = _allTasks.where((task) {
      if (q.isNotEmpty &&
          !task.title.toLowerCase().contains(q) &&
          !task.description.toLowerCase().contains(q)) {
        return false;
      }

      if (start != null) {
        final startAt = DateTime(start.year, start.month, start.day);
        if (task.dueDate == null || task.dueDate!.isBefore(startAt)) {
          return false;
        }
      }

      if (end != null) {
        final endAt = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
        if (task.dueDate == null || task.dueDate!.isAfter(endAt)) return false;
      }

      if (_groupFilter != 'all' && task.groupId != _groupFilter) {
        return false;
      }

      if (_streakFilter != null && task.streakEnabled != _streakFilter) {
        return false;
      }

      if (_completionFilter != null && task.isCompleted != _completionFilter) {
        return false;
      }

      if (_priorityFilters.isNotEmpty &&
          !_priorityFilters.contains(task.priority)) {
        return false;
      }

      if (_recurrenceFilters.isNotEmpty &&
          !_recurrenceFilters.contains(task.recurrence)) {
        return false;
      }

      return true;
    }).toList()..sort(_compareByDueDateAscending);

    setState(() => _results = filtered);
  }

  bool get _hasActiveFilters {
    return _startDate != null ||
        _endDate != null ||
        _groupFilter != 'all' ||
        _streakFilter != null ||
        _completionFilter != null ||
        _priorityFilters.isNotEmpty ||
        _recurrenceFilters.isNotEmpty;
  }

  Future<void> _openFilterSheet() async {
    DateTime? draftStart = _startDate;
    DateTime? draftEnd = _endDate;
    String draftGroup = _groupFilter;
    bool? draftStreak = _streakFilter;
    bool? draftCompletion = _completionFilter;
    final draftPriorities = Set<TaskPriority>.from(_priorityFilters);
    final draftRecurrences = Set<TaskRecurrence>.from(_recurrenceFilters);

    Future<DateTime?> pickDate(DateTime? initial) async {
      return showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String dateLabel(DateTime? date) {
              if (date == null) return 'Not set';
              return DateFormat('MMM d, yyyy').format(date);
            }

            Widget boolFilter({
              required String title,
              required bool? value,
              required ValueChanged<bool?> onChanged,
              String trueLabel = 'Yes',
              String falseLabel = 'No',
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any'),
                        selected: value == null,
                        onSelected: (_) => onChanged(null),
                      ),
                      ChoiceChip(
                        label: Text(trueLabel),
                        selected: value == true,
                        onSelected: (_) => onChanged(true),
                      ),
                      ChoiceChip(
                        label: Text(falseLabel),
                        selected: value == false,
                        onSelected: (_) => onChanged(false),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Search Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Date Range',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await pickDate(draftStart);
                                    if (picked == null) return;
                                    setSheetState(() => draftStart = picked);
                                  },
                                  child: Text(
                                    'Start: ${dateLabel(draftStart)}',
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Clear start date',
                                onPressed: draftStart == null
                                    ? null
                                    : () => setSheetState(
                                        () => draftStart = null,
                                      ),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final picked = await pickDate(draftEnd);
                                    if (picked == null) return;
                                    setSheetState(() => draftEnd = picked);
                                  },
                                  child: Text('End: ${dateLabel(draftEnd)}'),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Clear end date',
                                onPressed: draftEnd == null
                                    ? null
                                    : () =>
                                          setSheetState(() => draftEnd = null),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: draftGroup,
                      decoration: const InputDecoration(
                        labelText: 'Task Group',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All'),
                        ),
                        ..._groups.map(
                          (group) => DropdownMenuItem(
                            value: group.id,
                            child: Text('${group.icon} ${group.name}'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => draftGroup = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    boolFilter(
                      title: 'Streak',
                      value: draftStreak,
                      onChanged: (value) =>
                          setSheetState(() => draftStreak = value),
                      trueLabel: 'Streak On',
                      falseLabel: 'Streak Off',
                    ),
                    const SizedBox(height: 12),
                    boolFilter(
                      title: 'Status',
                      value: draftCompletion,
                      onChanged: (value) =>
                          setSheetState(() => draftCompletion = value),
                      trueLabel: 'Completed',
                      falseLabel: 'Active',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: TaskPriority.values.map((priority) {
                        final selected = draftPriorities.contains(priority);
                        return FilterChip(
                          label: Text(
                            priority.name[0].toUpperCase() +
                                priority.name.substring(1),
                          ),
                          selected: selected,
                          onSelected: (value) {
                            setSheetState(() {
                              if (value) {
                                draftPriorities.add(priority);
                              } else {
                                draftPriorities.remove(priority);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Recurrence',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: TaskRecurrence.values.map((recurrence) {
                        final selected = draftRecurrences.contains(recurrence);
                        return FilterChip(
                          label: Text(_recurrenceLabel(recurrence)),
                          selected: selected,
                          onSelected: (value) {
                            setSheetState(() {
                              if (value) {
                                draftRecurrences.add(recurrence);
                              } else {
                                draftRecurrences.remove(recurrence);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                draftStart = null;
                                draftEnd = null;
                                draftGroup = 'all';
                                draftStreak = null;
                                draftCompletion = null;
                                draftPriorities.clear();
                                draftRecurrences.clear();
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _startDate = draftStart;
                                _endDate = draftEnd;
                                _groupFilter = draftGroup;
                                _streakFilter = draftStreak;
                                _completionFilter = draftCompletion;
                                _priorityFilters = draftPriorities;
                                _recurrenceFilters = draftRecurrences;
                              });
                              Navigator.pop(context);
                              _applySearchAndFilters();
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _groupFilter = 'all';
      _streakFilter = null;
      _completionFilter = null;
      _priorityFilters.clear();
      _recurrenceFilters.clear();
    });
    _applySearchAndFilters();
  }

  String _recurrenceLabel(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return 'No repeat';
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekly:
        return 'Weekly';
      case TaskRecurrence.custom:
        return 'Custom';
      case TaskRecurrence.monthly:
        return 'Monthly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(title: 'Find Tasks'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'What are you looking for?',
                  hintStyle: const TextStyle(fontWeight: FontWeight.w600),
                  prefixIcon: const Icon(Icons.search_rounded, size: 28),
                  suffixIcon: IconButton(
                    tooltip: 'Filters',
                    onPressed: _openFilterSheet,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: _hasActiveFilters
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_startDate != null || _endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    'Date: ${_startDate == null ? '-' : DateFormat('MMM d').format(_startDate!)} to ${_endDate == null ? '-' : DateFormat('MMM d').format(_endDate!)}',
                                  ),
                                ),
                              ),
                            if (_groupFilter != 'all')
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text('Group: $_groupFilter'),
                                ),
                              ),
                            if (_streakFilter != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    _streakFilter! ? 'Streak On' : 'Streak Off',
                                  ),
                                ),
                              ),
                            if (_completionFilter != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    _completionFilter! ? 'Completed' : 'Active',
                                  ),
                                ),
                              ),
                            if (_priorityFilters.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    'Priority: ${_priorityFilters.map((e) => e.name).join(', ')}',
                                  ),
                                ),
                              ),
                            if (_recurrenceFilters.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    'Repeat: ${_recurrenceFilters.map(_recurrenceLabel).join(', ')}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _results.isEmpty
                  ? _buildEmptyState(hasQuery)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final task = _results[index];
                        return TaskCardWidget(
                          task: task,
                          group: _groupForTask(task),
                          showGroup: true,
                          onTap: () {},
                          onToggle: () {},
                          onPinToggle: task.isCompleted
                              ? null
                              : () => _togglePin(task),
                          onNotify: task.isCompleted
                              ? null
                              : () => _notifyTask(task),
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
    final scheme = Theme.of(context).colorScheme;
    return AppEmptyState(
      icon: hasQuery ? Icons.search_rounded : Icons.auto_awesome_rounded,
      title: 'Looking clear!',
      message: hasQuery ? 'No tasks match your search.' : 'No tasks found here.',
      accentColor: hasQuery ? scheme.primary : scheme.tertiary,
    );
  }
}
