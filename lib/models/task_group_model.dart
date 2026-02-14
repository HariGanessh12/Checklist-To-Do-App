
class TaskGroup {
  final String id;
  final String name;
  final String icon;
  final int colorValue;

  TaskGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'colorValue': colorValue,
  };

  factory TaskGroup.fromJson(Map<String, dynamic> json) => TaskGroup(
    id: json['id'],
    name: json['name'],
    icon: json['icon'],
    colorValue: json['colorValue'],
  );
}
