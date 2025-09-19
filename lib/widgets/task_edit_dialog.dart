import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _selectedTaskType = 'stepByStep';
  Recurrence? _recurrence;
  DateTime? _dueDate;
  DateTime? _plannedDate;
  Recurrence? _plannedRecurrence;

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _nameController.text = widget.initialTask!.name;
      _descriptionController.text = widget.initialTask!.description ?? '';
      _stepsController.text = widget.initialTask!.totalSteps.toString();
      _selectedTaskType = widget.initialTask!.taskType;
      _recurrence = widget.initialTask!.recurrence;
      _dueDate = widget.initialTask!.dueDate;
      _plannedDate = widget.initialTask!.plannedDate;
    } else {
      _stepsController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? "Создать задачу" : "Редактировать задачу"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Название задачи"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTaskType,
              items: const [
                DropdownMenuItem(value: "singleStep", child: Text("Одиночная")),
                DropdownMenuItem(value: "stepByStep", child: Text("Пошаговая")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedTaskType = val!;
                });
              },
              decoration: const InputDecoration(labelText: "Тип задачи"),
            ),
            if (_selectedTaskType == "stepByStep")
              TextFormField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Количество шагов"),
              ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Описание"),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_dueDate == null
                  ? 'Установить срок'
                  : 'Срок: ${DateFormat('dd.MM.yyyy').format(_dueDate!)}'),
              trailing: const Icon(Icons.event),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
            ListTile(
              title: Text(_plannedDate == null
                  ? 'Запланировать дату'
                  : 'Запланировано: ${DateFormat('dd.MM.yyyy').format(_plannedDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _plannedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _plannedDate = date);
                }
              },
            ),
            DropdownButtonFormField<RecurrenceType>(
              value: _plannedRecurrence?.type,
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(Recurrence(type: type).displayText),
                );
              }).toList(),
              onChanged: (type) {
                setState(() {
                  _plannedRecurrence = Recurrence(type: type!);
                });
              },
              decoration: const InputDecoration(labelText: 'Повторение планирования'),
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
          onPressed: _saveTask,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }

  void _saveTask() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final steps = _selectedTaskType == "stepByStep"
        ? (int.tryParse(_stepsController.text) ?? 1)
        : 1;

    final task = Task(
      name: name,
      totalSteps: steps,
      completedSteps: widget.initialTask?.completedSteps ?? 0,
      stages: widget.initialTask?.stages ?? [],
      taskType: _selectedTaskType,
      recurrence: _recurrence,
      dueDate: _dueDate,
      isCompleted: widget.initialTask?.isCompleted ?? false,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      plannedDate: _plannedDate,
    );

    widget.onSave(task);
    Navigator.pop(context);
  }
}