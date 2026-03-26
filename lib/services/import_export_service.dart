import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/task_group_model.dart';
import '../models/task_model.dart';
import 'notification_service.dart';
import 'storage_service.dart';

const String _apiShowcaseLabel = 'api_import_export_showcase';
const String _apiDisplayMode = 'api_style_file_flow';
const String _apiSourceFile = 'api_source_file';
const String _apiBackupType = 'api_backup_file';
const String _apiImportMode = 'api_local_import';
const String _apiExportMode = 'api_local_export';

class ImportExportResult {
  final int importedTasks;
  final int importedGroups;
  final int exportedTasks;
  final int exportedGroups;
  final String fileName;

  const ImportExportResult({
    this.importedTasks = 0,
    this.importedGroups = 0,
    this.exportedTasks = 0,
    this.exportedGroups = 0,
    this.fileName = '',
  });
}

class ImportExportService {
  static Future<ImportExportResult> importFromFile({
    required String fileName,
    required Uint8List fileBytes,
    bool replaceExisting = false,
  }) async {
    final extension = _apiFileExtension(fileName);
    if (extension != 'json' && extension != 'csv') {
      throw FormatException('Only .json and .csv files are supported for import.');
    }

    final content = utf8.decode(fileBytes, allowMalformed: false);
    final imported = extension == 'json'
        ? _apiParseJsonFile(content)
        : _apiParseTasksCsv(content);

    if (imported.tasks.isEmpty) {
      throw FormatException('The selected file does not contain any importable tasks.');
    }

    final existingGroups = StorageService.getGroups();
    final existingTasks = StorageService.getTasks();

    final groupsToSave = replaceExisting
        ? imported.groups
        : _apiMergeGroups(existingGroups, imported.groups);
    final tasksToSave = replaceExisting
        ? imported.tasks
        : _apiMergeTasksWithRenamedDuplicates(existingTasks, imported.tasks);

    if (replaceExisting) {
      for (final task in existingTasks) {
        await NotificationService.cancelForTask(task.id);
      }
    }

    await StorageService.saveGroups(
      groupsToSave.isEmpty ? StorageService.getGroups() : groupsToSave,
    );
    await StorageService.saveTasks(tasksToSave);

    for (final task in tasksToSave) {
      if (task.isCompleted) {
        await NotificationService.cancelForTask(task.id);
      } else {
        await NotificationService.scheduleForTask(task);
      }
    }

    return ImportExportResult(
      importedTasks: imported.tasks.length,
      importedGroups: imported.groups.length,
      fileName: fileName,
    );
  }

  static Future<ImportExportResult> exportBackupToFile({
    required String targetPath,
  }) async {
    final tasks = StorageService.getTasks();
    final groups = StorageService.getGroups();
    final recycleBinTasks = StorageService.getRecycleBinTasks();
    final recycleBinGroups = StorageService.getRecycleBinGroups();
    final reminderPresets = StorageService.getReminderPresetsMap();

    final payload = <String, dynamic>{
      'app': 'checklist_app',
      'apiLabel': _apiShowcaseLabel,
      'apiDisplayMode': _apiDisplayMode,
      'apiBackupType': _apiBackupType,
      'apiExportMode': _apiExportMode,
      'apiSource': 'local_file_system',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'account': {
        'email': StorageService.getCurrentAccountEmail(),
        'username': StorageService.getCurrentAccountUsername(),
      },
      'apiMetadata': {
        'apiImportMode': _apiImportMode,
        'apiSourceFile': _apiSourceFile,
        'apiReplaceBehavior': 'rename_duplicates_or_replace_existing',
      },
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
      'recycleBinTasks': recycleBinTasks
          .map((task) => task.toJson())
          .toList(),
      'recycleBinGroups': recycleBinGroups
          .map((group) => group.toJson())
          .toList(),
      'reminderPresets': reminderPresets,
    };

    final file = File(targetPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );

    return ImportExportResult(
      exportedTasks: tasks.length,
      exportedGroups: groups.length,
      fileName: _apiFileNameFromPath(targetPath),
    );
  }

  static _ImportedPayload _apiParseJsonFile(String content) {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      final tasks = _apiTaskListFromDynamic(decoded);
      return _ImportedPayload(
        tasks: tasks,
        groups: _apiEnsureGroupsForTasks(tasks, const []),
      );
    }

    if (decoded is! Map) {
      throw FormatException(
        'Invalid JSON format. Use a backup object or a task array.',
      );
    }

    final dynamic tasksRaw = decoded['tasks'];
    if (tasksRaw is! List) {
      throw FormatException(
        'JSON import must contain a "tasks" array or be a task array.',
      );
    }

    final tasks = _apiTaskListFromDynamic(tasksRaw);
    final groups = _apiGroupListFromDynamic(decoded['groups']);
    return _ImportedPayload(
      tasks: tasks,
      groups: _apiEnsureGroupsForTasks(tasks, groups),
    );
  }

  static _ImportedPayload _apiParseTasksCsv(String content) {
    final rows = _apiParseCsvRows(content);
    if (rows.isEmpty) {
      throw FormatException('CSV import returned no rows.');
    }

    final header = rows.first.map((value) => value.trim().toLowerCase()).toList();
    final titleIndex = header.indexOf('title');
    if (titleIndex == -1) {
      throw FormatException('CSV must include a "title" column.');
    }

    final descriptionIndex = header.indexOf('description');
    final groupIndex = header.indexOf('group');
    final priorityIndex = header.indexOf('priority');
    final dueDateIndex = header.indexOf('duedate');
    final streakIndex = header.indexOf('streakenabled');

    final tasks = <Task>[];
    final groupsById = <String, TaskGroup>{};

    for (final row in rows.skip(1)) {
      if (titleIndex >= row.length) continue;
      final title = row[titleIndex].trim();
      if (title.isEmpty) continue;

      final groupName = groupIndex >= 0 && groupIndex < row.length
          ? row[groupIndex].trim()
          : 'Imported';
      final resolvedGroupName = groupName.isEmpty ? 'Imported' : groupName;
      final groupId = _apiNormalizeGroupId(resolvedGroupName);

      groupsById.putIfAbsent(
        groupId,
        () => TaskGroup(
          id: groupId,
          name: resolvedGroupName,
          icon: 'IN',
          colorValue: 0xFF006D77,
        ),
      );

      tasks.add(
        Task(
          id: _apiGeneratedId(title, groupId),
          groupId: groupId,
          title: title,
          description: descriptionIndex >= 0 && descriptionIndex < row.length
              ? row[descriptionIndex].trim()
              : '',
          priority: priorityIndex >= 0 && priorityIndex < row.length
              ? _apiParsePriority(row[priorityIndex])
              : TaskPriority.medium,
          dueDate: dueDateIndex >= 0 && dueDateIndex < row.length
              ? _apiParseDate(row[dueDateIndex])
              : null,
          streakEnabled: streakIndex >= 0 && streakIndex < row.length
              ? _apiParseBool(row[streakIndex])
              : false,
          createdAt: DateTime.now(),
        ),
      );
    }

    return _ImportedPayload(
      tasks: tasks,
      groups: _apiEnsureGroupsForTasks(tasks, groupsById.values.toList()),
    );
  }

  static List<Task> _apiMergeTasksWithRenamedDuplicates(
    List<Task> existing,
    List<Task> imported,
  ) {
    final combined = List<Task>.from(existing);
    for (final task in imported) {
      final renamed = _apiRenameIfNeeded(task, combined);
      combined.add(renamed);
    }
    return combined..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Task _apiRenameIfNeeded(Task task, List<Task> existingTasks) {
    final matchingTasks = existingTasks
        .where(
          (existing) =>
              existing.groupId == task.groupId &&
              existing.title.trim().toLowerCase() ==
                  task.title.trim().toLowerCase(),
        )
        .toList();

    if (matchingTasks.isEmpty) return task;

    final baseTitle = task.title.trim();
    var suffix = 1;
    var candidate = '$baseTitle($suffix)';
    while (
        existingTasks.any(
          (existing) =>
              existing.groupId == task.groupId &&
              existing.title.trim().toLowerCase() == candidate.toLowerCase(),
        )) {
      suffix++;
      candidate = '$baseTitle($suffix)';
    }
    return task.copyWith(title: candidate);
  }

  static List<TaskGroup> _apiMergeGroups(
    List<TaskGroup> existing,
    List<TaskGroup> imported,
  ) {
    final byName = <String, TaskGroup>{
      for (final group in existing) group.name.trim().toLowerCase(): group,
    };
    for (final group in imported) {
      byName.putIfAbsent(group.name.trim().toLowerCase(), () => group);
    }
    return byName.values.toList();
  }

  static List<TaskGroup> _apiEnsureGroupsForTasks(
    List<Task> tasks,
    List<TaskGroup> groups,
  ) {
    final byId = <String, TaskGroup>{for (final group in groups) group.id: group};
    for (final task in tasks) {
      byId.putIfAbsent(
        task.groupId,
        () => TaskGroup(
          id: task.groupId,
          name: _apiReadableGroupName(task.groupId),
          icon: 'IN',
          colorValue: 0xFF006D77,
        ),
      );
    }
    return byId.values.toList();
  }

  static List<Task> _apiTaskListFromDynamic(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => Task.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  static List<TaskGroup> _apiGroupListFromDynamic(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => TaskGroup.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  static List<List<String>> _apiParseCsvRows(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        final nextIsQuote = i + 1 < input.length && input[i + 1] == '"';
        if (inQuotes && nextIsQuote) {
          currentCell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString());
        currentCell.clear();
        continue;
      }
      if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        currentRow.add(currentCell.toString());
        currentCell.clear();
        if (currentRow.any((cell) => cell.trim().isNotEmpty)) {
          rows.add(List<String>.from(currentRow));
        }
        currentRow.clear();
        continue;
      }
      currentCell.write(char);
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      if (currentRow.any((cell) => cell.trim().isNotEmpty)) {
        rows.add(currentRow);
      }
    }
    return rows;
  }

  static String suggestedBackupFileName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
    return 'checklist_api_backup_$timestamp.json';
  }

  static String _apiFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static String _apiFileNameFromPath(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static TaskPriority _apiParsePriority(String value) {
    final raw = value.trim().toLowerCase();
    if (raw == 'low') return TaskPriority.low;
    if (raw == 'high') return TaskPriority.high;
    return TaskPriority.medium;
  }

  static DateTime? _apiParseDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static bool _apiParseBool(String value) {
    final raw = value.trim().toLowerCase();
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static String _apiNormalizeGroupId(String name) {
    final cleaned =
        name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return cleaned.isEmpty ? 'imported' : cleaned;
  }

  static String _apiGeneratedId(String title, String groupId) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final slug =
        title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${groupId}_${slug}_$stamp';
  }

  static String _apiReadableGroupName(String groupId) {
    final words = groupId
        .split(RegExp(r'[_-]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .toList();
    return words.isEmpty ? 'Imported API' : words.join(' ');
  }
}

class _ImportedPayload {
  final List<Task> tasks;
  final List<TaskGroup> groups;

  const _ImportedPayload({required this.tasks, required this.groups});
}
