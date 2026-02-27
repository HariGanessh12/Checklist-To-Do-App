import '../models/task_model.dart';

class TaskTemplate {
  final String id;
  final String name;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final int? recurrenceIntervalDays;
  final List<Subtask> subtasks;

  const TaskTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.priority,
    required this.recurrence,
    this.recurrenceIntervalDays,
    this.subtasks = const [],
  });
}

class TaskTemplateService {
  static const List<TaskTemplate> templates = [
    TaskTemplate(
      id: 'morning_routine',
      name: 'Morning Routine',
      title: 'Morning routine',
      description: 'Start the day with the essentials.',
      priority: TaskPriority.medium,
      recurrence: TaskRecurrence.daily,
      subtasks: [
        Subtask(title: 'Drink water'),
        Subtask(title: 'Stretch for 10 minutes'),
        Subtask(title: 'Plan top 3 priorities'),
      ],
    ),
    TaskTemplate(
      id: 'release_checklist',
      name: 'Release Checklist',
      title: 'Release checklist',
      description: 'Final checks before shipping.',
      priority: TaskPriority.high,
      recurrence: TaskRecurrence.none,
      subtasks: [
        Subtask(title: 'Run tests'),
        Subtask(title: 'Update changelog'),
        Subtask(title: 'Tag release'),
        Subtask(title: 'Notify stakeholders'),
      ],
    ),
    TaskTemplate(
      id: 'weekly_review',
      name: 'Weekly Review',
      title: 'Weekly review',
      description: 'Review wins, blockers, and priorities for next week.',
      priority: TaskPriority.medium,
      recurrence: TaskRecurrence.weekly,
      subtasks: [
        Subtask(title: 'Review completed tasks'),
        Subtask(title: 'List blockers'),
        Subtask(title: 'Plan next week goals'),
      ],
    ),
  ];
}
