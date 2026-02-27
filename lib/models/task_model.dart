enum TaskPriority { low, medium, high }

enum TaskRecurrence { none, daily, weekly, custom }

class Task {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final bool isCompleted;
  final bool notificationEnabled;
  final TaskRecurrence recurrence;
  final int? recurrenceIntervalDays;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.groupId,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    required this.dueDate,
    this.isCompleted = false,
    this.notificationEnabled = true,
    this.recurrence = TaskRecurrence.none,
    this.recurrenceIntervalDays,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    bool? notificationEnabled,
    TaskRecurrence? recurrence,
    int? recurrenceIntervalDays,
    String? groupId,
  }) {
    return Task(
      id: id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      recurrence: recurrence ?? this.recurrence,
      recurrenceIntervalDays:
          recurrenceIntervalDays ?? this.recurrenceIntervalDays,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'priority': priority.index,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'notificationEnabled': notificationEnabled,
      'recurrence': recurrence.index,
      'recurrenceIntervalDays': recurrenceIntervalDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      groupId: json['groupId'],
      title: json['title'],
      description: json['description'],
      priority: TaskPriority.values[json['priority']],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
      notificationEnabled: json['notificationEnabled'] ?? true,
      recurrence: TaskRecurrence.values[json['recurrence'] ?? 0],
      recurrenceIntervalDays: json['recurrenceIntervalDays'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
