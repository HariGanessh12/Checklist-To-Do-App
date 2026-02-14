
class AppConstants {
  static const String appName = "Material Tasks";
  static const String tasksKey = "m3_tasks_storage";
  static const String groupsKey = "m3_groups_storage";
  static const String settingsKey = "m3_settings_storage";

  static final List<Map<String, dynamic>> defaultGroups = [
    {'id': 'personal', 'name': 'Personal', 'icon': '👤', 'colorValue': 0xFF6750A4},
    {'id': 'work', 'name': 'Work', 'icon': '💼', 'colorValue': 0xFF0061A4},
    {'id': 'study', 'name': 'Study', 'icon': '📚', 'colorValue': 0xFF006A60},
    {'id': 'shopping', 'name': 'Shopping', 'icon': '🛒', 'colorValue': 0xFF984061},
  ];
}

