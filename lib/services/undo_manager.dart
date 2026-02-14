
import '../models/task_model.dart';

enum UndoType { delete, complete }

class UndoAction {
  final UndoType type;
  final Task task;
  final int originalIndex;

  UndoAction({required this.type, required this.task, required this.originalIndex});
}

class UndoManager {
  static UndoAction? _lastAction;

  static void setLastAction(UndoType type, Task task, int index) {
    _lastAction = UndoAction(type: type, task: task, originalIndex: index);
  }

  static UndoAction? get lastAction => _lastAction;
  
  static void clear() => _lastAction = null;
}
