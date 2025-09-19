import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../models/step.dart' as custom_step;
import '../models/recurrence.dart';

class StepEditDialog extends StatefulWidget {
  final Function(custom_step.Step) onSave;
  final custom_step.Step? initialStep;

  const StepEditDialog({
    super.key,
    required this.onSave,
    this.initialStep,
  });

  @override
  State<StepEditDialog> createState() => _StepEditDialogState();
}

class _StepEditDialogState extends State<StepEditDialog> {
  final _nameController = TextEditingController();
  final _stepsController = TextEditingController();
  String _selectedStepType = 'stepByStep';
  DateTime? _plannedDate;
  Recurrence? _plannedRecurrence;

  @override
  void initState() {
    super.initState();
    if (widget.initialStep != null) {
      _nameController.text = widget.initialStep!.name;
      _stepsController.text = widget.initialStep!.totalSteps.toString();
      _selectedStepType = widget.initialStep!.stepType;
      _plannedDate = widget.initialStep!.plannedDate;
    } else {
      _stepsController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialStep == null ? "Создать шаг" : "Редактировать шаг"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Название шага"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStepType,
              items: const [
                DropdownMenuItem(value: "singleStep", child: Text("Одиночный")),
                DropdownMenuItem(value: "stepByStep", child: Text("Пошаговый")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedStepType = val!;
                });
              },
              decoration: const InputDecoration(labelText: "Тип шага"),
            ),
            if (_selectedStepType == "stepByStep")
              TextFormField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Количество шагов"),
              ),
            const SizedBox(height: 16),
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
          onPressed: _saveStep,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }

  void _saveStep() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final steps = _selectedStepType == "stepByStep"
        ? (int.tryParse(_stepsController.text) ?? 1)
        : 1;

    final step = TaskService.createStep(
      name,
      steps,
      stepType: _selectedStepType,
    );

    widget.onSave(step);
    Navigator.pop(context);
  }
}