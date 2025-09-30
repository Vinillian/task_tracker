import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../models/recurrence.dart';
import 'dart:math'; // ← ДОБАВИТЬ ДЛЯ PI И ТРИГОНОМЕТРИЧЕСКИХ ФУНКЦИЙ

// Вспомогательный класс для хранения информации о цвете (ВЫНЕСТИ ЗА ПРЕДЕЛЫ КЛАССА)
class _ColorOption {
  final String name;
  final int value;
  final IconData icon;
  final MaterialColor color;

  _ColorOption(this.name, this.value, this.icon, this.color);
}

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
  int _selectedColor = 0xFF2196F3; // Синий по умолчанию

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
      _selectedColor = widget.initialTask!.colorValue ?? 0xFF2196F3; // ← ДОБАВИТЬ ?? 0xFF2196F3
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
            _buildColorPicker(),
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
                  ? 'Запланировать дату выполнения'
                  : 'Запланировано: ${DateFormat('dd.MM.yyyy').format(_plannedDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _plannedDate ?? _dueDate ?? DateTime.now(),
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

  bool _isColorPickerExpanded = false;

  Widget _buildColorPicker() {
    final colorMatrix = [
      [0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 0xFF009688, 0xFF4CAF50, 0xFF8BC34A],
      [0xFFCDDC39, 0xFFFFC107, 0xFFFF9800, 0xFFFF5722, 0xFFF44336, 0xFFE91E63],
      [0xFF9C27B0, 0xFF673AB7, 0xFF3F51B5, 0xFF607D8B, 0xFF9E9E9E, 0xFF795548],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Выпадающая палитра (теперь сверху)
        if (_isColorPickerExpanded) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: colorMatrix.map((row) {
                return Row(
                  children: row.map((colorValue) {
                    return Expanded(
                      child: Container(
                        height: 22,
                        margin: const EdgeInsets.all(0.5),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = colorValue;
                              _isColorPickerExpanded = false; // Закрыть после выбора
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(colorValue),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: _selectedColor == colorValue
                                    ? Colors.black
                                    : Colors.transparent,
                                width: _selectedColor == colorValue ? 2 : 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Строка с индикатором (теперь снизу)
        Row(
          children: [
            // Индикатор цвета (кнопка для открытия/закрытия палитры)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isColorPickerExpanded = !_isColorPickerExpanded;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(_selectedColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
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
      colorValue: _selectedColor,
    );

    widget.onSave(task);
    Navigator.pop(context);
  }
}