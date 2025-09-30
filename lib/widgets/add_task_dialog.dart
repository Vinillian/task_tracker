// widgets/add_task_dialog.dart
import 'package:flutter/material.dart';
import '../models/task_type.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, TaskType, int) onTaskCreated;

  const AddTaskDialog({
    super.key,
    required this.onTaskCreated,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  String _title = '';
  String _description = '';
  TaskType _type = TaskType.single;
  int _steps = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить задачу'),
      content: Column(
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
                    child: Text(type == TaskType.single ? 'Одиночная' : 'Пошаговая'),
                  );
                }).toList(),
              ),
            ],
          ),

          // ✅ КОЛИЧЕСТВО ШАГОВ (только для пошаговых)
          if (_type == TaskType.stepByStep) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Количество шагов:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _steps,
                  onChanged: (int? newValue) {
                    setState(() {
                      _steps = newValue!;
                    });
                  },
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((int steps) {
                    return DropdownMenuItem<int>(
                      value: steps,
                      child: Text('$steps'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_title.isNotEmpty) {
              widget.onTaskCreated(_title, _description, _type, _steps);
              Navigator.pop(context);
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}