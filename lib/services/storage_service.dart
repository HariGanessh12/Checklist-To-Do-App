
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/task_group_model.dart';
import '../core/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Tasks ---
  static List<Task> getTasks() {
    final String? data = _prefs?.getString(AppConstants.tasksKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => Task.fromJson(e)).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final String data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.tasksKey, data);
  }

  // --- Groups ---
  static List<TaskGroup> getGroups() {
    final String? data = _prefs?.getString(AppConstants.groupsKey);
    if (data == null) {
       return AppConstants.defaultGroups.map((e) => TaskGroup.fromJson(e)).toList();
    }
    final List decoded = jsonDecode(data);
    return decoded.map((e) => TaskGroup.fromJson(e)).toList();
  }

  static Future<void> saveGroups(List<TaskGroup> groups) async {
    final String data = jsonEncode(groups.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.groupsKey, data);
  }

  // --- Settings ---
  static bool getAnimationsEnabled() {
    return _prefs?.getBool(AppConstants.settingsKey) ?? true;
  }

  static Future<void> saveAnimationsEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.settingsKey, enabled);
  }

  // --- Global ---
  static Future<void> clearAllData() async {
    await _prefs?.clear();
  }
}
