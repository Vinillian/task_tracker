// widgets/subtask_edit_dialog.dart
import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/subtask.dart'; // ← ДОБАВИТЬ этот импорт

class SubtaskEditDialog extends StatefulWidget {
  final Function(Subtask) onSave;
  final Subtask? initialSubtask;

  const SubtaskEditDialog({
    super.key,
    required this.onSave,
    this.initialSubtask,
  });

  @override
  State<SubtaskEditDialog> createState() => _SubtaskEditDialogState();
}

class _SubtaskEditDialogState extends State<SubtaskEditDialog> {
  final _nameController = TextEditingController();
  final _stepsController = TextEditingController();
  String _selectedSubtaskType = 'stepByStep';

  @override
  void initState() {
    super.initState();
    if (widget.initialSubtask != null) {
      _nameController.text = widget.initialSubtask!.name;
      _stepsController.text = widget.initialSubtask!.totalSteps.toString();
      _selectedSubtaskType = widget.initialSubtask!.subtaskType;
    } else {
      _stepsController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialSubtask == null ? "Создать подзадачу" : "Редактировать подзадачу"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Название подзадачи"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubtaskType,
              items: const [
                DropdownMenuItem(value: "singleStep", child: Text("Одиночная")),
                DropdownMenuItem(value: "stepByStep", child: Text("Пошаговая")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSubtaskType = val!;
                });
              },
              decoration: const InputDecoration(labelText: "Тип подзадачи"),
            ),
            if (_selectedSubtaskType == "stepByStep")
              TextFormField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Количество шагов"),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: _saveSubtask,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }

  void _saveSubtask() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final steps = _selectedSubtaskType == "stepByStep"
        ? (int.tryParse(_stepsController.text) ?? 1)
        : 1;

    final subtask = TaskService.createSubtask(
      name,
      steps,
      subtaskType: _selectedSubtaskType,
    );

    widget.onSave(subtask);
    Navigator.pop(context);
  }
}