import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../models/recurrence.dart';

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
      _selectedColor = widget.initialTask!.colorValue;
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

  Widget _buildColorPicker() {
    final colors = [
      _ColorOption('Красный', 0xFFF44336, Icons.circle, Colors.red),
      _ColorOption('Розовый', 0xFFE91E63, Icons.circle, Colors.pink),
      _ColorOption('Фиолетовый', 0xFF9C27B0, Icons.circle, Colors.purple),
      _ColorOption('Глубокий фиолетовый', 0xFF673AB7, Icons.circle, Colors.deepPurple),
      _ColorOption('Индиго', 0xFF3F51B5, Icons.circle, Colors.indigo),
      _ColorOption('Синий', 0xFF2196F3, Icons.circle, Colors.blue),
      _ColorOption('Голубой', 0xFF03A9F4, Icons.circle, Colors.lightBlue),
      _ColorOption('Бирюзовый', 0xFF00BCD4, Icons.circle, Colors.cyan),
      _ColorOption('Зеленый', 0xFF009688, Icons.circle, Colors.teal),
      _ColorOption('Светло-зеленый', 0xFF4CAF50, Icons.circle, Colors.green),
      _ColorOption('Лаймовый', 0xFF8BC34A, Icons.circle, Colors.lightGreen),
      _ColorOption('Желтый', 0xFFCDDC39, Icons.circle, Colors.yellow),
      _ColorOption('Янтарный', 0xFFFFC107, Icons.circle, Colors.amber),
      _ColorOption('Оранжевый', 0xFFFF9800, Icons.circle, Colors.orange),
      _ColorOption('Глубокий оранжевый', 0xFFFF5722, Icons.circle, Colors.deepOrange),
      _ColorOption('Коричневый', 0xFF795548, Icons.circle, Colors.brown),
      _ColorOption('Серый', 0xFF9E9E9E, Icons.circle, Colors.grey),
      _ColorOption('Сине-серый', 0xFF607D8B, Icons.circle, Colors.blueGrey),
    ];

    // Находим текущий выбранный цвет
    final currentColor = colors.firstWhere(
          (color) => color.value == _selectedColor,
      orElse: () => colors.firstWhere((color) => color.value == 0xFF2196F3),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Цвет задачи:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<_ColorOption>(
          value: currentColor,
          items: colors.map((colorOption) {
            return DropdownMenuItem<_ColorOption>(
              value: colorOption,
              child: Row(
                children: [
                  Icon(
                    colorOption.icon,
                    color: colorOption.color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(colorOption.name),
                  const Spacer(),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(colorOption.value),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (colorOption) {
            if (colorOption != null) {
              setState(() {
                _selectedColor = colorOption.value;
              });
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Цвет будет отображаться в кружке прогресса задачи',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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