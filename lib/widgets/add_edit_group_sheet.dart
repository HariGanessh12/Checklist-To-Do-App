
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_group_model.dart';

class AddEditGroupSheet extends StatefulWidget {
  final Function(TaskGroup) onSave;
  final TaskGroup? groupToEdit;

  const AddEditGroupSheet({super.key, required this.onSave, this.groupToEdit});

  @override
  State<AddEditGroupSheet> createState() => _AddEditGroupSheetState();
}

class _AddEditGroupSheetState extends State<AddEditGroupSheet> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;

  final List<String> _icons = ['📁', '💼', '📚', '🛒', '🏠', '🎯', '🎨', '🚀', '💊', '🍽️', '🎮', '💡'];
  final List<int> _colors = [0xFF6750A4, 0xFF0061A4, 0xFF006A60, 0xFF984061, 0xFF7D5260, 0xFFB3261E, 0xFF605D62, 0xFF2E7D32];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupToEdit?.name ?? '');
    _selectedIcon = widget.groupToEdit?.icon ?? _icons.first;
    _selectedColor = widget.groupToEdit?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text(widget.groupToEdit == null ? "New Group" : "Edit Group", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            const Text("Choose Icon", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _selectedIcon = _icons[i]),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _selectedIcon == _icons[i] ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(_icons[i], style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Choose Color", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = _colors[i]),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Color(_colors[i]),
                      shape: BoxShape.circle,
                      border: _selectedColor == _colors[i] ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: () {
                  if (_nameController.text.isEmpty) return;
                  final group = TaskGroup(
                    id: widget.groupToEdit?.id ?? const Uuid().v4(),
                    name: _nameController.text.trim(),
                    icon: _selectedIcon,
                    colorValue: _selectedColor,
                  );
                  widget.onSave(group);
                  Navigator.pop(context);
                },
                child: const Text("Save Group"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
