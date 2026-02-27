import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const int _maxNotificationSlots = 4;

  static Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await requestPermissions();
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
    final offsets = _priorityOffsets(task.priority);
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
        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription: 'Reminders for upcoming tasks',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: scheduleMode,
          payload: task.id,
        );
      } on PlatformException {
        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription: 'Reminders for upcoming tasks',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
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

  static List<Duration> _priorityOffsets(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const [
          Duration(days: -1),
          Duration(hours: -1),
          Duration.zero,
          Duration(minutes: 15),
        ];
      case TaskPriority.medium:
        return const [Duration(hours: -1), Duration.zero];
      case TaskPriority.low:
        return const [Duration.zero];
    }
  }

  static List<DateTime> upcomingReminderTimes(Task task, {DateTime? now}) {
    if (task.isCompleted || !task.notificationEnabled) return const [];
    final current = now ?? DateTime.now();
    return _priorityOffsets(task.priority)
        .map((offset) => task.dueDate.add(offset))
        .where((time) => !time.isBefore(current))
        .toList()
      ..sort();
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
}
