import '../models/task_model.dart';
import 'storage_service.dart';
import 'package:uuid/uuid.dart';

class TaskTemplate {
  final String id;
  final String name;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final int? recurrenceIntervalDays;
  final List<Subtask> subtasks;
  final bool isBuiltIn;

  const TaskTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.priority,
    required this.recurrence,
    this.recurrenceIntervalDays,
    this.subtasks = const [],
    this.isBuiltIn = false,
  });

  TaskTemplate copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskRecurrence? recurrence,
    int? recurrenceIntervalDays,
    List<Subtask>? subtasks,
    bool? isBuiltIn,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      recurrenceIntervalDays:
          recurrenceIntervalDays ?? this.recurrenceIntervalDays,
      subtasks: subtasks ?? this.subtasks,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'priority': priority.index,
      'recurrence': recurrence.index,
      'recurrenceIntervalDays': recurrenceIntervalDays,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
      'isBuiltIn': isBuiltIn,
    };
  }

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priority: TaskPriority.values[(json['priority'] ?? 1) as int],
      recurrence: TaskRecurrence.values[(json['recurrence'] ?? 0) as int],
      recurrenceIntervalDays: json['recurrenceIntervalDays'] as int?,
      subtasks: (json['subtasks'] as List? ?? const [])
          .map((entry) => Subtask.fromJson(Map<String, dynamic>.from(entry)))
          .toList(),
      isBuiltIn: (json['isBuiltIn'] ?? false) as bool,
    );
  }
}

class TaskTemplateService {
  static const List<TaskTemplate> _builtInTemplates = [
    TaskTemplate(
      id: 'morning_routine',
      name: 'Morning Routine',
      title: 'Morning routine',
      description: 'Start the day with the essentials.',
      priority: TaskPriority.medium,
      recurrence: TaskRecurrence.daily,
      isBuiltIn: true,
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
      isBuiltIn: true,
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
      isBuiltIn: true,
      subtasks: [
        Subtask(title: 'Review completed tasks'),
        Subtask(title: 'List blockers'),
        Subtask(title: 'Plan next week goals'),
      ],
    ),
  ];

  static List<TaskTemplate> _customTemplates = [];

  static Future<void> init() async {
    final saved = StorageService.getTemplatesList();
    _customTemplates = saved
        .map(TaskTemplate.fromJson)
        .map((template) => template.copyWith(isBuiltIn: false))
        .toList();
  }

  static List<TaskTemplate> get builtInTemplates => _builtInTemplates;

  static List<TaskTemplate> get customTemplates =>
      List<TaskTemplate>.unmodifiable(_customTemplates);

  static List<TaskTemplate> get templates => [
    ..._builtInTemplates,
    ..._customTemplates,
  ];

  static TaskTemplate? getById(String id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  static Future<void> addCustomTemplate(TaskTemplate template) async {
    _customTemplates.insert(0, template.copyWith(isBuiltIn: false));
    await _persist();
  }

  static Future<void> updateCustomTemplate(TaskTemplate template) async {
    final idx = _customTemplates.indexWhere((entry) => entry.id == template.id);
    if (idx == -1) return;
    _customTemplates[idx] = template.copyWith(isBuiltIn: false);
    await _persist();
  }

  static Future<void> deleteCustomTemplate(String templateId) async {
    _customTemplates.removeWhere((entry) => entry.id == templateId);
    await _persist();
  }

  static Future<TaskTemplate> createFromTask(Task task, {String? name}) async {
    final template = TaskTemplate(
      id: const Uuid().v4(),
      name: (name == null || name.trim().isEmpty) ? task.title : name.trim(),
      title: task.title,
      description: task.description,
      priority: task.priority,
      recurrence: task.recurrence,
      recurrenceIntervalDays: task.recurrenceIntervalDays,
      subtasks: task.subtasks
          .map(
            (subtask) =>
                Subtask(title: subtask.title, isCompleted: subtask.isCompleted),
          )
          .toList(),
      isBuiltIn: false,
    );
    await addCustomTemplate(template);
    return template;
  }

  static Future<void> _persist() async {
    await StorageService.saveTemplatesList(
      _customTemplates.map((template) => template.toJson()).toList(),
    );
  }
}
