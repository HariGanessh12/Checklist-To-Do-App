import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';
import 'reminder_preset_service.dart';
import 'storage_service.dart';

const String _snooze10mActionId = 'snooze_10m';
const String _snooze1hActionId = 'snooze_1h';
const String _snoozeTomorrowActionId = 'snooze_tomorrow';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  NotificationService.handleNotificationResponse(notificationResponse);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const int _maxNotificationSlots = 7;
  static const int _snooze10mSlot = 4;
  static const int _snooze1hSlot = 5;
  static const int _snoozeTomorrowSlot = 6;
  static const List<AndroidNotificationAction> _androidSnoozeActions = [
    AndroidNotificationAction(_snooze10mActionId, 'Snooze 10m'),
    AndroidNotificationAction(_snooze1hActionId, 'Snooze 1h'),
    AndroidNotificationAction(_snoozeTomorrowActionId, 'Tomorrow'),
  ];

  static Future<void> init() async {
    if (_isInitialized) return;
    await _initPluginCore();
    await requestPermissions();
  }

  static Future<void> _initPluginCore() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimeZone();
    await ReminderPresetService.init();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Checklist App',
      appUserModelId: 'com.example.checklist_app',
      guid: '2f4c4e1f-c45d-4f59-bf5a-9be6a7d8f2b1',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      windows: windowsSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _isInitialized = true;
  }

  static Future<void> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final canExact = await android?.canScheduleExactNotifications();
    if (canExact == false) {
      await android?.requestExactAlarmsPermission();
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<int> scheduleForTask(Task task) async {
    await init();
    await cancelForTask(task.id);

    if (task.isCompleted || !task.notificationEnabled) return 0;

    final now = DateTime.now();
    var scheduledCount = 0;
    final offsets = ReminderPresetService.getOffsets(task.priority);
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (var i = 0; i < offsets.length; i++) {
      final scheduledTime = task.dueDate.add(offsets[i]);
      if (scheduledTime.isBefore(now)) continue;

      final notificationId = _notificationId(task.id, i);
      final title = _titleForOffset(offsets[i], task.priority);
      final body = 'Task: ${task.title}';

      try {
        await _scheduleAt(
          notificationId: notificationId,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          payload: task.id,
          scheduleMode: scheduleMode,
        );
      } on PlatformException {
        await _scheduleAt(
          notificationId: notificationId,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          payload: task.id,
          scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      scheduledCount++;
    }

    return scheduledCount;
  }

  static Future<void> cancelForTask(String taskId) async {
    await init();
    for (var slot = 0; slot < _maxNotificationSlots; slot++) {
      await _notifications.cancel(_notificationId(taskId, slot));
    }
  }

  static List<DateTime> upcomingReminderTimes(Task task, {DateTime? now}) {
    if (task.isCompleted || !task.notificationEnabled) return const [];
    final current = now ?? DateTime.now();
    return ReminderPresetService.getOffsets(task.priority)
        .map((offset) => task.dueDate.add(offset))
        .where((time) => !time.isBefore(current))
        .toList()
      ..sort();
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final actionId = response.actionId;
    if (actionId != _snooze10mActionId &&
        actionId != _snooze1hActionId &&
        actionId != _snoozeTomorrowActionId) {
      return;
    }

    final taskId = response.payload;
    if (taskId == null || taskId.isEmpty) return;

    await _initPluginCore();
    await StorageService.init();
    final tasks = StorageService.getTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = tasks[taskIndex];
    if (task.isCompleted || !task.notificationEnabled) return;

    final now = DateTime.now();
    DateTime snoozeUntil;
    var snoozeSlot = _snooze10mSlot;
    if (actionId == _snooze10mActionId) {
      snoozeUntil = now.add(const Duration(minutes: 10));
      snoozeSlot = _snooze10mSlot;
    } else if (actionId == _snooze1hActionId) {
      snoozeUntil = now.add(const Duration(hours: 1));
      snoozeSlot = _snooze1hSlot;
    } else {
      snoozeUntil = DateTime(
        now.year,
        now.month,
        now.day + 1,
        now.hour,
        now.minute,
      );
      snoozeSlot = _snoozeTomorrowSlot;
    }

    final notificationId = _notificationId(task.id, snoozeSlot);
    final title = 'Snoozed Reminder';
    final body = 'Task: ${task.title}';

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _scheduleAt(
        notificationId: notificationId,
        title: title,
        body: body,
        scheduledTime: snoozeUntil,
        payload: task.id,
        scheduleMode: scheduleMode,
      );
    } on PlatformException {
      await _scheduleAt(
        notificationId: notificationId,
        title: title,
        body: body,
        scheduledTime: snoozeUntil,
        payload: task.id,
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static String _titleForOffset(Duration offset, TaskPriority priority) {
    if (offset == Duration.zero) return 'Task Due Now';
    if (offset.isNegative) {
      if (offset == const Duration(days: -1)) {
        return 'High Priority Task Due Tomorrow';
      }
      if (offset == const Duration(hours: -1)) return 'Task Due in 1 Hour';
      return 'Task Reminder';
    }
    if (offset == const Duration(minutes: 15) &&
        priority == TaskPriority.high) {
      return 'Still Pending: High Priority Task';
    }
    return 'Task Reminder';
  }

  static int _notificationId(String taskId, int slot) {
    final base = _stableHash(taskId) & 0x1fffffff;
    return (base * 10 + slot) & 0x7fffffff;
  }

  static int _stableHash(String value) {
    var hash = 5381;
    for (final code in value.codeUnits) {
      hash = ((hash << 5) + hash + code) & 0x7fffffff;
    }
    return hash;
  }

  static Future<void> _configureLocalTimeZone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(_normalizeTimeZone(timeZoneName)));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  static String _normalizeTimeZone(String timeZoneName) {
    const aliases = <String, String>{
      'Asia/Calcutta': 'Asia/Kolkata',
      'US/Pacific': 'America/Los_Angeles',
      'US/Mountain': 'America/Denver',
      'US/Central': 'America/Chicago',
      'US/Eastern': 'America/New_York',
    };
    return aliases[timeZoneName] ?? timeZoneName;
  }

  static Future<void> _scheduleAt({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required AndroidScheduleMode scheduleMode,
  }) async {
    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for upcoming tasks',
          importance: Importance.max,
          priority: Priority.high,
          actions: _androidSnoozeActions,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      payload: payload,
    );
  }
}
