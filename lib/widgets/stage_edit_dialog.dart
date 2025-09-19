import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../models/stage.dart';
import '../models/recurrence.dart';

class StageEditDialog extends StatefulWidget {
  final Function(Stage) onSave;
  final Stage? initialStage;

  const StageEditDialog({
    super.key,
    required this.onSave,
    this.initialStage,
  });

  @override
  State<StageEditDialog> createState() => _StageEditDialogState();
}

class _StageEditDialogState extends State<StageEditDialog> {
  final _nameController = TextEditingController();
  final _stepsController = TextEditingController();
  String _selectedStageType = 'stepByStep';
  DateTime? _plannedDate;
  Recurrence? _plannedRecurrence;

  @override
  void initState() {
    super.initState();
    if (widget.initialStage != null) {
      _nameController.text = widget.initialStage!.name;
      _stepsController.text = widget.initialStage!.totalSteps.toString();
      _selectedStageType = widget.initialStage!.stageType;
      _plannedDate = widget.initialStage!.plannedDate;
    } else {
      _stepsController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialStage == null ? "Создать этап" : "Редактировать этап"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Название этапа"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStageType,
              items: const [
                DropdownMenuItem(value: "singleStep", child: Text("Одиночный")),
                DropdownMenuItem(value: "stepByStep", child: Text("Пошаговый")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedStageType = val!;
                });
              },
              decoration: const InputDecoration(labelText: "Тип этапа"),
            ),
            if (_selectedStageType == "stepByStep")
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
          onPressed: _saveStage,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }

  void _saveStage() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final steps = _selectedStageType == "stepByStep"
        ? (int.tryParse(_stepsController.text) ?? 1)
        : 1;

    final stage = TaskService.createStage(
      name,
      steps,
      stageType: _selectedStageType,
    );

    widget.onSave(stage);
    Navigator.pop(context);
  }
}