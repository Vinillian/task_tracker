import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../models/recurrence.dart';

class TaskEditDialog extends StatefulWidget {
  final Task? initialTask;
  final Function(Task) onSave;

  const TaskEditDialog({
    super.key,
    this.initialTask,
    required this.onSave,
  });

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  TaskType _selectedType = TaskType.stepByStep;
  Recurrence? _recurrence;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _nameController.text = widget.initialTask!.name;
      _descriptionController.text = widget.initialTask!.description ?? '';
      _stepsController.text = widget.initialTask!.totalSteps.toString();
      _selectedType = widget.initialTask!.taskType;
      _recurrence = widget.initialTask!.recurrence;
      _dueDate = widget.initialTask!.dueDate;
    } else {
      _stepsController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? 'Новая задача' : 'Редактировать задачу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название задачи'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
              maxLines: 3,
            ),
            DropdownButtonFormField<TaskType>(
              value: _selectedType,
              items: TaskType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Тип задачи'),
            ),
            if (_selectedType == TaskType.stepByStep)
              TextField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Количество шагов'),
              ),
            // TODO: Добавить выбор периодичности и даты выполнения
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _saveTask,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _saveTask() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final steps = int.tryParse(_stepsController.text) ?? 1;

    final task = Task(
      name: name,
      totalSteps: steps,
      completedSteps: widget.initialTask?.completedSteps ?? 0,
      subtasks: widget.initialTask?.subtasks ?? [],
      taskType: _selectedType,
      recurrence: _recurrence,
      dueDate: _dueDate,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    widget.onSave(task);
    Navigator.pop(context);
  }
}