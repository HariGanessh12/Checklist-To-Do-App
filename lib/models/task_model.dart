enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final bool isCompleted;
  final bool notificationEnabled;
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
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    bool? notificationEnabled,
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
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
