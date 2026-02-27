import '../models/task_model.dart';
import 'storage_service.dart';

class ReminderPresetService {
  static bool _isInitialized = false;

  static final Map<TaskPriority, List<int>> _defaultMinutesByPriority = {
    TaskPriority.high: [-1440, -60, 0, 15],
    TaskPriority.medium: [-60, 0],
    TaskPriority.low: [0],
  };

  static Map<TaskPriority, List<int>> _minutesByPriority = {
    TaskPriority.high: List<int>.from(
      _defaultMinutesByPriority[TaskPriority.high]!,
    ),
    TaskPriority.medium: List<int>.from(
      _defaultMinutesByPriority[TaskPriority.medium]!,
    ),
    TaskPriority.low: List<int>.from(
      _defaultMinutesByPriority[TaskPriority.low]!,
    ),
  };

  static Future<void> init() async {
    if (_isInitialized) return;
    final saved = StorageService.getReminderPresetsMap();
    if (saved != null) {
      _minutesByPriority = {
        TaskPriority.high: _read(saved['high'], TaskPriority.high),
        TaskPriority.medium: _read(saved['medium'], TaskPriority.medium),
        TaskPriority.low: _read(saved['low'], TaskPriority.low),
      };
    }
    _isInitialized = true;
  }

  static List<Duration> getOffsets(TaskPriority priority) {
    final minutes =
        _minutesByPriority[priority] ??
        _defaultMinutesByPriority[priority] ??
        const <int>[0];
    return minutes.map((value) => Duration(minutes: value)).toList();
  }

  static Map<TaskPriority, List<int>> getAllPresetMinutes() {
    return {
      TaskPriority.high: List<int>.from(
        _minutesByPriority[TaskPriority.high] ?? const <int>[],
      ),
      TaskPriority.medium: List<int>.from(
        _minutesByPriority[TaskPriority.medium] ?? const <int>[],
      ),
      TaskPriority.low: List<int>.from(
        _minutesByPriority[TaskPriority.low] ?? const <int>[],
      ),
    };
  }

  static Future<void> savePriorityPreset(
    TaskPriority priority,
    List<int> minuteOffsets,
  ) async {
    final normalized = _normalize(minuteOffsets);
    _minutesByPriority[priority] = normalized;
    await StorageService.saveReminderPresetsMap({
      'high': _minutesByPriority[TaskPriority.high],
      'medium': _minutesByPriority[TaskPriority.medium],
      'low': _minutesByPriority[TaskPriority.low],
    });
  }

  static List<int> _read(dynamic raw, TaskPriority priority) {
    if (raw is! List) {
      return List<int>.from(_defaultMinutesByPriority[priority]!);
    }
    final values = <int>[];
    for (final entry in raw) {
      if (entry is int) {
        values.add(entry);
      }
    }
    final normalized = _normalize(values);
    if (normalized.isEmpty) {
      return List<int>.from(_defaultMinutesByPriority[priority]!);
    }
    return normalized;
  }

  static List<int> _normalize(List<int> input) {
    final unique = <int>{};
    for (final value in input) {
      unique.add(value.clamp(-10080, 10080));
    }
    final result = unique.toList()..sort();
    return result;
  }
}
