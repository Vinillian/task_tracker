// widgets/add_task_dialog.dart
import 'package:flutter/material.dart';
import '../models/task_type.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, TaskType, int, String?) onTaskCreated;
  final String projectId; // ✅ ДОБАВЛЯЕМ projectId
  final String? parentId; // ✅ ДОБАВЛЯЕМ parentId (null для корневых задач)

  const AddTaskDialog({
    super.key,
    required this.onTaskCreated,
    required this.projectId,
    this.parentId,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  String _title = '';
  String _description = '';
  TaskType _type = TaskType.single;
  int _steps = 1;
  late TextEditingController _stepsController;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(text: _steps.toString());
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSubTask = widget.parentId != null;

    return AlertDialog(
      title: Text(isSubTask ? 'Добавить подзадачу' : 'Добавить задачу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Название задачи*',
                hintText: 'Например: Сделать домашку',
              ),
              onChanged: (value) => _title = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Описание задачи',
                hintText: 'Подробное описание',
              ),
              onChanged: (value) => _description = value,
            ),
            const SizedBox(height: 16),

            // ✅ ВЫБОР ТИПА ЗАДАЧИ
            Row(
              children: [
                const Text('Тип задачи:'),
                const SizedBox(width: 16),
                DropdownButton<TaskType>(
                  value: _type,
                  onChanged: (TaskType? newValue) {
                    setState(() {
                      _type = newValue!;
                    });
                  },
                  items: TaskType.values.map((TaskType type) {
                    return DropdownMenuItem<TaskType>(
                      value: type,
                      child: Text(
                          type == TaskType.single ? 'Одиночная' : 'Пошаговая'),
                    );
                  }).toList(),
                ),
              ],
            ),

            // ✅ ПОЛЕ КОЛИЧЕСТВА ШАГОВ (только для пошаговых задач)
            if (_type == TaskType.stepByStep) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Количество шагов:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _stepsController,
                      decoration: const InputDecoration(
                        hintText: 'Введите число',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final steps = int.tryParse(value) ?? 1;
                        setState(() {
                          _steps = steps.clamp(1, 100);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _steps = (_steps + 1).clamp(1, 100);
                            _stepsController.text = _steps.toString();
                          });
                        },
                        tooltip: 'Увеличить',
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            _steps = (_steps - 1).clamp(1, 100);
                            _stepsController.text = _steps.toString();
                          });
                        },
                        tooltip: 'Уменьшить',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_title.isNotEmpty) {
              final steps = _type == TaskType.stepByStep ? _steps : 1;
              // ✅ ИСПРАВЛЕНО: правильное количество параметров
              widget.onTaskCreated(_title, _description, _type, steps, widget.parentId);
              Navigator.pop(context);
            }
          },
          child: Text(isSubTask ? 'Добавить подзадачу' : 'Добавить задачу'),
        ),
      ],
    );
  }
}