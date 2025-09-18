import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/step.dart' as custom_step; // ← переименовываем

class StepEditDialog extends StatefulWidget {
  final Function(custom_step.Step) onSave; // ← используем переименованный
  final custom_step.Step? initialStep; // ← используем переименованный

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

  @override
  void initState() {
    super.initState();
    if (widget.initialStep != null) {
      _nameController.text = widget.initialStep!.name;
      _stepsController.text = widget.initialStep!.totalSteps.toString();
      _selectedStepType = widget.initialStep!.stepType;
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