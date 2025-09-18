import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/stage.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialStage != null) {
      _nameController.text = widget.initialStage!.name;
      _stepsController.text = widget.initialStage!.totalSteps.toString();
      _selectedStageType = widget.initialStage!.stageType;
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