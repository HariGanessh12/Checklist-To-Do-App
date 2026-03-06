import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/task_template_service.dart';

class TemplateManagerPage extends StatefulWidget {
  const TemplateManagerPage({super.key});

  @override
  State<TemplateManagerPage> createState() => _TemplateManagerPageState();
}

class _TemplateManagerPageState extends State<TemplateManagerPage> {
  List<TaskTemplate> _builtIn = [];
  List<TaskTemplate> _custom = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _builtIn = TaskTemplateService.builtInTemplates;
      _custom = TaskTemplateService.customTemplates;
    });
  }

  Future<void> _createTemplate() async {
    final draft = await _openEditor(context);
    if (draft == null) return;
    await TaskTemplateService.addCustomTemplate(
      TaskTemplate(
        id: const Uuid().v4(),
        name: draft.name,
        title: draft.title,
        description: draft.description,
        priority: draft.priority,
        recurrence: draft.recurrence,
        recurrenceIntervalDays: draft.recurrenceIntervalDays,
        subtasks: draft.subtasks,
      ),
    );
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Template created')));
  }

  Future<void> _editTemplate(TaskTemplate template) async {
    final draft = await _openEditor(context, existing: template);
    if (draft == null) return;
    await TaskTemplateService.updateCustomTemplate(
      template.copyWith(
        name: draft.name,
        title: draft.title,
        description: draft.description,
        priority: draft.priority,
        recurrence: draft.recurrence,
        recurrenceIntervalDays: draft.recurrenceIntervalDays,
        subtasks: draft.subtasks,
      ),
    );
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Template updated')));
  }

  Future<void> _deleteTemplate(TaskTemplate template) async {
    await TaskTemplateService.deleteCustomTemplate(template.id);
    _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Template deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Template Manager')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTemplate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Template'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          const Text(
            'Built-in',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._builtIn.map((template) => _TemplateTile(template: template)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Custom',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text('${_custom.length}'),
            ],
          ),
          const SizedBox(height: 8),
          if (_custom.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No custom templates yet.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ..._custom.map(
            (template) => _TemplateTile(
              template: template,
              onEdit: () => _editTemplate(template),
              onDelete: () => _deleteTemplate(template),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final TaskTemplate template;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TemplateTile({required this.template, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final canEdit = !template.isBuiltIn;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(template.name),
        subtitle: Text(template.title),
        trailing: canEdit
            ? Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ],
              )
            : const Chip(label: Text('Built-in')),
      ),
    );
  }
}

class _TemplateDraft {
  final String name;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskRecurrence recurrence;
  final int? recurrenceIntervalDays;
  final List<Subtask> subtasks;

  const _TemplateDraft({
    required this.name,
    required this.title,
    required this.description,
    required this.priority,
    required this.recurrence,
    this.recurrenceIntervalDays,
    required this.subtasks,
  });
}

Future<_TemplateDraft?> _openEditor(
  BuildContext context, {
  TaskTemplate? existing,
}) {
  return showModalBottomSheet<_TemplateDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TemplateEditorSheet(existing: existing),
  );
}

class _TemplateEditorSheet extends StatefulWidget {
  final TaskTemplate? existing;

  const _TemplateEditorSheet({this.existing});

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _customDaysController;
  late TaskPriority _priority;
  late TaskRecurrence _recurrence;
  late List<Subtask> _subtasks;
  late List<TextEditingController> _subtaskControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _customDaysController = TextEditingController(
      text: (widget.existing?.recurrenceIntervalDays ?? 2).toString(),
    );
    _priority = widget.existing?.priority ?? TaskPriority.medium;
    _recurrence = widget.existing?.recurrence ?? TaskRecurrence.none;
    _subtasks = List<Subtask>.from(widget.existing?.subtasks ?? const []);
    _subtaskControllers = _subtasks
        .map((subtask) => TextEditingController(text: subtask.title))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _customDaysController.dispose();
    for (final controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtask() {
    setState(() {
      _subtasks.add(const Subtask(title: ''));
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtasks.removeAt(index);
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    if (name.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and title are required')),
      );
      return;
    }
    int? recurrenceDays;
    if (_recurrence == TaskRecurrence.custom) {
      recurrenceDays = int.tryParse(_customDaysController.text.trim());
      if (recurrenceDays == null || recurrenceDays < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom recurrence must be >= 1 day')),
        );
        return;
      }
    }
    final subtasks = <Subtask>[];
    for (var i = 0; i < _subtasks.length; i++) {
      final title = _subtaskControllers[i].text.trim();
      if (title.isEmpty) continue;
      subtasks.add(_subtasks[i].copyWith(title: title));
    }
    Navigator.pop(
      context,
      _TemplateDraft(
        name: name,
        title: title,
        description: _descriptionController.text.trim(),
        priority: _priority,
        recurrence: _recurrence,
        recurrenceIntervalDays: recurrenceDays,
        subtasks: subtasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Create Template' : 'Edit Template',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(
                        priority.name[0].toUpperCase() +
                            priority.name.substring(1),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskRecurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskRecurrence.none,
                  child: Text('No Repeat'),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.custom,
                  child: Text('Custom'),
                ),
                DropdownMenuItem(
                  value: TaskRecurrence.monthly,
                  child: Text('Monthly'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _recurrence = value);
              },
            ),
            if (_recurrence == TaskRecurrence.custom) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repeat every (days)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subtasks',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            ...List.generate(_subtasks.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Subtask title',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeSubtask(index),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(
                  widget.existing == null ? 'Create Template' : 'Save Template',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
