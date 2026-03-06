import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';
import '../core/app_constants.dart';
import 'home_screen_widget_service.dart';
import 'recurrence_service.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static final ValueNotifier<bool> animationsEnabledNotifier =
      ValueNotifier<bool>(true);
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    animationsEnabledNotifier.value = getAnimationsEnabled();
    themeModeNotifier.value = getThemeMode();
  }

  // --- Tasks ---
  static List<Task> getTasks() {
    final String? data = _prefs?.getString(AppConstants.tasksKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    final tasks = decoded.map((e) => Task.fromJson(e)).toList();
    final migrated = _migrateIndividualTasksToPersonal(tasks);
    final pruned = _pruneOldCompletedTasks(migrated);
    final rolled = RecurrenceService.rollOverMissedDailyTasks(pruned);
    if (!identical(tasks, rolled)) {
      saveTasks(rolled);
    }
    return rolled;
  }

  static List<Task> _migrateIndividualTasksToPersonal(List<Task> tasks) {
    var changed = false;
    final migrated = tasks.map((task) {
      if (task.groupId != 'individual') return task;
      changed = true;
      return task.copyWith(groupId: 'personal');
    }).toList();
    return changed ? migrated : tasks;
  }

  static List<Task> _pruneOldCompletedTasks(List<Task> tasks, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final cutoff = current.subtract(const Duration(days: 10));
    var changed = false;
    final filtered = tasks.where((task) {
      if (!task.isCompleted) return true;
      final completedAt = task.completedAt;
      if (completedAt == null) return true;
      final keep = !completedAt.isBefore(cutoff);
      if (!keep) changed = true;
      return keep;
    }).toList();
    return changed ? filtered : tasks;
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final String data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.tasksKey, data);
    await HomeScreenWidgetService.updateWidgets();
  }

  // --- Recycle Bin Tasks ---
  static List<Task> getRecycleBinTasks() {
    final String? data = _prefs?.getString(AppConstants.recycleBinTasksKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((entry) => Task.fromJson(entry)).toList();
  }

  static Future<void> saveRecycleBinTasks(List<Task> tasks) async {
    final String data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.recycleBinTasksKey, data);
  }

  static Future<void> addTasksToRecycleBin(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    final existing = getRecycleBinTasks();
    final byId = <String, Task>{for (final task in existing) task.id: task};
    for (final task in tasks) {
      byId[task.id] = task;
    }
    await saveRecycleBinTasks(byId.values.toList());
  }

  static Future<void> removeTasksFromRecycleBinById(List<String> taskIds) async {
    if (taskIds.isEmpty) return;
    final idSet = taskIds.toSet();
    final filtered = getRecycleBinTasks()
        .where((task) => !idSet.contains(task.id))
        .toList();
    await saveRecycleBinTasks(filtered);
  }

  // --- Groups ---
  static List<TaskGroup> getGroups() {
    final String? data = _prefs?.getString(AppConstants.groupsKey);
    if (data == null) {
      return AppConstants.defaultGroups
          .map((e) => TaskGroup.fromJson(e))
          .toList();
    }
    final List decoded = jsonDecode(data);
    return decoded.map((e) => TaskGroup.fromJson(e)).toList();
  }

  static Future<void> saveGroups(List<TaskGroup> groups) async {
    final String data = jsonEncode(groups.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.groupsKey, data);
  }

  // --- Recycle Bin Groups ---
  static List<TaskGroup> getRecycleBinGroups() {
    final String? data = _prefs?.getString(AppConstants.recycleBinGroupsKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((entry) => TaskGroup.fromJson(entry)).toList();
  }

  static Future<void> saveRecycleBinGroups(List<TaskGroup> groups) async {
    final String data = jsonEncode(groups.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.recycleBinGroupsKey, data);
  }

  static Future<void> addGroupToRecycleBin(TaskGroup group) async {
    final existing = getRecycleBinGroups();
    final filtered = existing.where((entry) => entry.id != group.id).toList();
    filtered.insert(0, group);
    await saveRecycleBinGroups(filtered);
  }

  static Future<void> removeGroupsFromRecycleBinById(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return;
    final idSet = groupIds.toSet();
    final filtered = getRecycleBinGroups()
        .where((group) => !idSet.contains(group.id))
        .toList();
    await saveRecycleBinGroups(filtered);
  }

  // --- Settings ---
  static bool getAnimationsEnabled() {
    return _prefs?.getBool(AppConstants.settingsKey) ?? true;
  }

  static Future<void> saveAnimationsEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.settingsKey, enabled);
    animationsEnabledNotifier.value = enabled;
  }

  // --- Theme ---
  static ThemeMode getThemeMode() {
    final String? raw = _prefs?.getString(AppConstants.themeModeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final String raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs?.setString(AppConstants.themeModeKey, raw);
    themeModeNotifier.value = mode;
  }

  // --- Reminder Presets ---
  static Map<String, dynamic>? getReminderPresetsMap() {
    final String? data = _prefs?.getString(AppConstants.reminderPresetsKey);
    if (data == null || data.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static Future<void> saveReminderPresetsMap(Map<String, dynamic> data) async {
    final String encoded = jsonEncode(data);
    await _prefs?.setString(AppConstants.reminderPresetsKey, encoded);
    await HomeScreenWidgetService.updateWidgets();
  }

  // --- Global ---
  static Future<void> clearAllData() async {
    await _prefs?.clear();
    animationsEnabledNotifier.value = true;
    themeModeNotifier.value = ThemeMode.system;
    await HomeScreenWidgetService.updateWidgets();
  }
}
