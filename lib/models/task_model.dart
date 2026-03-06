enum TaskPriority { low, medium, high }

enum TaskRecurrence { none, daily, weekly, custom, monthly }

class Subtask {
  final String title;
  final bool isCompleted;

  const Subtask({required this.title, this.isCompleted = false});

  Subtask copyWith({String? title, bool? isCompleted}) {
    return Subtask(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'isCompleted': isCompleted};
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Task {
  static const Object _unsetDueDate = Object();
  final String id;
  final String groupId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool streakEnabled;
  final bool isPinned;
  final bool notificationEnabled;
  final TaskRecurrence recurrence;
  final int? recurrenceIntervalDays;
  final List<Subtask> subtasks;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.groupId,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.streakEnabled = false,
    this.isPinned = false,
    this.notificationEnabled = true,
    this.recurrence = TaskRecurrence.none,
    this.recurrenceIntervalDays,
    this.subtasks = const [],
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    Object? dueDate = _unsetDueDate,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? streakEnabled,
    bool? isPinned,
    bool? notificationEnabled,
    TaskRecurrence? recurrence,
    int? recurrenceIntervalDays,
    List<Subtask>? subtasks,
    String? groupId,
  }) {
    return Task(
      id: id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: identical(dueDate, _unsetDueDate)
          ? this.dueDate
          : dueDate as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      streakEnabled: streakEnabled ?? this.streakEnabled,
      isPinned: isPinned ?? this.isPinned,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      recurrence: recurrence ?? this.recurrence,
      recurrenceIntervalDays:
          recurrenceIntervalDays ?? this.recurrenceIntervalDays,
      subtasks: subtasks ?? this.subtasks,
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
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'streakEnabled': streakEnabled,
      'isPinned': isPinned,
      'notificationEnabled': notificationEnabled,
      'recurrence': recurrence.index,
      'recurrenceIntervalDays': recurrenceIntervalDays,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
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
      dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'],
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt']),
      streakEnabled: json['streakEnabled'] ?? false,
      isPinned: json['isPinned'] ?? false,
      notificationEnabled: json['notificationEnabled'] ?? true,
      recurrence: TaskRecurrence.values[json['recurrence'] ?? 0],
      recurrenceIntervalDays: json['recurrenceIntervalDays'],
      subtasks:
          (json['subtasks'] as List?)
              ?.map(
                (entry) => Subtask.fromJson(Map<String, dynamic>.from(entry)),
              )
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
