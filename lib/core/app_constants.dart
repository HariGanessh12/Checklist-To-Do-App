class AppConstants {
  static const String appName = "Material Tasks";
  static const String tasksKey = "m3_tasks_storage";
  static const String groupsKey = "m3_groups_storage";
  static const String settingsKey = "m3_settings_storage";
  static const String themeModeKey = "m3_theme_mode_storage";
  static const String reminderPresetsKey = "m3_reminder_presets_storage";
  static const String recycleBinTasksKey = "m3_recycle_bin_tasks_storage";
  static const String recycleBinGroupsKey = "m3_recycle_bin_groups_storage";
  static const String authUsernameKey = "m3_auth_username_storage";
  static const String authPasswordKey = "m3_auth_password_storage";
  static const String authSignedInKey = "m3_auth_signed_in_storage";
  static const String authAccountsKey = "m3_auth_accounts_storage";
  static const String authCurrentEmailKey = "m3_auth_current_email_storage";

  static final List<Map<String, dynamic>> defaultGroups = [
    {
      'id': 'personal',
      'name': 'Personal',
      'icon': '👤',
      'colorValue': 0xFF006D77,
    },
    {'id': 'work', 'name': 'Work', 'icon': '💼', 'colorValue': 0xFF0061A4},
    {'id': 'study', 'name': 'Study', 'icon': '📚', 'colorValue': 0xFF006A60},
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': '🛒',
      'colorValue': 0xFF984061,
    },
  ];
}
