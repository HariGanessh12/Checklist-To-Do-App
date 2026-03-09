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
  static final ValueNotifier<bool> authSignedInNotifier =
      ValueNotifier<bool>(false);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacySingleAccountAuth();
    await _migrateLegacyUnscopedData();
    await _removeAccountAndData('hariganessh12@gmail.com');
    animationsEnabledNotifier.value = getAnimationsEnabled();
    themeModeNotifier.value = getThemeMode();
    authSignedInNotifier.value = isSignedIn();
  }

  static String _scopeKey(String baseKey) {
    final email = _prefs?.getString(AppConstants.authCurrentEmailKey);
    if (email == null || email.isEmpty) return '${baseKey}_guest';
    return '${baseKey}_${email.toLowerCase()}';
  }

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static Map<String, dynamic> _getAccountsMap() {
    final raw = _prefs?.getString(AppConstants.authAccountsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> _saveAccountsMap(Map<String, dynamic> accounts) async {
    await _prefs?.setString(AppConstants.authAccountsKey, jsonEncode(accounts));
  }

  static Future<void> _migrateLegacySingleAccountAuth() async {
    final accounts = _getAccountsMap();
    if (accounts.isNotEmpty) return;
    final legacyUsername = _prefs?.getString(AppConstants.authUsernameKey);
    final legacyPassword = _prefs?.getString(AppConstants.authPasswordKey);
    if (legacyUsername == null ||
        legacyUsername.isEmpty ||
        legacyPassword == null ||
        legacyPassword.isEmpty) {
      return;
    }
    final legacyEmail = _normalizeEmail(legacyUsername);
    await _saveAccountsMap({
      legacyEmail: {'username': legacyUsername, 'password': legacyPassword},
    });
    await _prefs?.setString(AppConstants.authCurrentEmailKey, legacyEmail);
  }

  static Future<void> _migrateLegacyUnscopedData() async {
    final currentEmail = _prefs?.getString(AppConstants.authCurrentEmailKey);
    if (currentEmail == null || currentEmail.isEmpty) return;

    Future<void> moveIfNeeded(String legacyKey) async {
      final scopedKey = _scopeKey(legacyKey);
      final scopedValue = _prefs?.getString(scopedKey);
      final legacyValue = _prefs?.getString(legacyKey);
      if ((scopedValue == null || scopedValue.isEmpty) &&
          legacyValue != null &&
          legacyValue.isNotEmpty) {
        await _prefs?.setString(scopedKey, legacyValue);
      }
    }

    await moveIfNeeded(AppConstants.tasksKey);
    await moveIfNeeded(AppConstants.groupsKey);
    await moveIfNeeded(AppConstants.recycleBinTasksKey);
    await moveIfNeeded(AppConstants.recycleBinGroupsKey);
    await moveIfNeeded(AppConstants.reminderPresetsKey);
  }

  static String _scopedKeyForEmail(String baseKey, String email) {
    return '${baseKey}_${_normalizeEmail(email)}';
  }

  static Future<void> _removeAccountAndData(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final accounts = _getAccountsMap();
    if (accounts.containsKey(normalizedEmail)) {
      accounts.remove(normalizedEmail);
      await _saveAccountsMap(accounts);
    }

    final keys = <String>[
      AppConstants.tasksKey,
      AppConstants.groupsKey,
      AppConstants.recycleBinTasksKey,
      AppConstants.recycleBinGroupsKey,
      AppConstants.reminderPresetsKey,
    ];
    for (final key in keys) {
      await _prefs?.remove(_scopedKeyForEmail(key, normalizedEmail));
    }

    final currentEmail = _prefs?.getString(AppConstants.authCurrentEmailKey);
    if (currentEmail == normalizedEmail) {
      await _prefs?.remove(AppConstants.authCurrentEmailKey);
      await _prefs?.setBool(AppConstants.authSignedInKey, false);
      authSignedInNotifier.value = false;
    }
  }

  // --- Tasks ---
  static List<Task> getTasks() {
    final String? data = _prefs?.getString(_scopeKey(AppConstants.tasksKey));
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
    await _prefs?.setString(_scopeKey(AppConstants.tasksKey), data);
    await HomeScreenWidgetService.updateWidgets();
  }

  // --- Recycle Bin Tasks ---
  static List<Task> getRecycleBinTasks() {
    final String? data = _prefs?.getString(
      _scopeKey(AppConstants.recycleBinTasksKey),
    );
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((entry) => Task.fromJson(entry)).toList();
  }

  static Future<void> saveRecycleBinTasks(List<Task> tasks) async {
    final String data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await _prefs?.setString(_scopeKey(AppConstants.recycleBinTasksKey), data);
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
    final String? data = _prefs?.getString(_scopeKey(AppConstants.groupsKey));
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
    await _prefs?.setString(_scopeKey(AppConstants.groupsKey), data);
  }

  // --- Recycle Bin Groups ---
  static List<TaskGroup> getRecycleBinGroups() {
    final String? data = _prefs?.getString(
      _scopeKey(AppConstants.recycleBinGroupsKey),
    );
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((entry) => TaskGroup.fromJson(entry)).toList();
  }

  static Future<void> saveRecycleBinGroups(List<TaskGroup> groups) async {
    final String data = jsonEncode(groups.map((e) => e.toJson()).toList());
    await _prefs?.setString(_scopeKey(AppConstants.recycleBinGroupsKey), data);
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
    final String? data = _prefs?.getString(
      _scopeKey(AppConstants.reminderPresetsKey),
    );
    if (data == null || data.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static Future<void> saveReminderPresetsMap(Map<String, dynamic> data) async {
    final String encoded = jsonEncode(data);
    await _prefs?.setString(_scopeKey(AppConstants.reminderPresetsKey), encoded);
    await HomeScreenWidgetService.updateWidgets();
  }

  // --- Local Auth ---
  static bool hasAnyLocalAccount() {
    return _getAccountsMap().isNotEmpty;
  }

  static bool hasLocalAccount() {
    return hasAnyLocalAccount();
  }

  static String? getLocalAccountUsername() {
    return getCurrentAccountUsername();
  }

  static String? getSignedInUsername() {
    if (!isSignedIn()) return null;
    return getCurrentAccountUsername();
  }

  static String? getCurrentAccountEmail() {
    return _prefs?.getString(AppConstants.authCurrentEmailKey);
  }

  static String? getCurrentAccountUsername() {
    final email = getCurrentAccountEmail();
    if (email == null || email.isEmpty) return null;
    final accounts = _getAccountsMap();
    final account = accounts[email];
    if (account is! Map) return null;
    return account['username']?.toString();
  }

  static bool isSignedIn() {
    return _prefs?.getBool(AppConstants.authSignedInKey) ?? false;
  }

  static Future<bool> registerLocalAccount(
    String username,
    String email,
    String password,
  ) async {
    final normalizedEmail = _normalizeEmail(email);
    final accounts = _getAccountsMap();
    if (accounts.containsKey(normalizedEmail)) return false;
    accounts[normalizedEmail] = {'username': username.trim(), 'password': password};
    await _saveAccountsMap(accounts);
    await _prefs?.setString(AppConstants.authCurrentEmailKey, normalizedEmail);
    await _prefs?.setBool(AppConstants.authSignedInKey, true);
    authSignedInNotifier.value = true;
    return true;
  }

  static Future<bool> signInLocal(String email, String password) async {
    final normalizedEmail = _normalizeEmail(email);
    final accounts = _getAccountsMap();
    final account = accounts[normalizedEmail];
    if (account is! Map) return false;
    final storedPassword = account['password']?.toString();
    if (storedPassword != password) return false;
    await _prefs?.setString(AppConstants.authCurrentEmailKey, normalizedEmail);
    await _prefs?.setBool(AppConstants.authSignedInKey, true);
    authSignedInNotifier.value = true;
    return true;
  }

  static Future<void> signOutLocal() async {
    await _prefs?.setBool(AppConstants.authSignedInKey, false);
    authSignedInNotifier.value = false;
  }

  static Future<void> bindCurrentDataToUser(String username) async {
    if (!hasAnyLocalAccount()) return;
    final normalizedEmail = _normalizeEmail(username);
    final accounts = _getAccountsMap();
    if (accounts.containsKey(normalizedEmail)) {
      await _prefs?.setString(AppConstants.authCurrentEmailKey, normalizedEmail);
    }
  }

  // --- Global ---
  static Future<void> clearAllData() async {
    await _prefs?.remove(_scopeKey(AppConstants.tasksKey));
    await _prefs?.remove(_scopeKey(AppConstants.groupsKey));
    await _prefs?.remove(_scopeKey(AppConstants.recycleBinTasksKey));
    await _prefs?.remove(_scopeKey(AppConstants.recycleBinGroupsKey));
    await _prefs?.remove(_scopeKey(AppConstants.reminderPresetsKey));
    animationsEnabledNotifier.value = true;
    themeModeNotifier.value = ThemeMode.system;
    await _prefs?.setBool(AppConstants.settingsKey, true);
    await _prefs?.remove(AppConstants.themeModeKey);
    authSignedInNotifier.value = false;
    await _prefs?.setBool(AppConstants.authSignedInKey, false);
    await HomeScreenWidgetService.updateWidgets();
  }
}
