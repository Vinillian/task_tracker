import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
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
  int _selectedColor = 0xFF2196F3;

  // Новые переменные для повторения
  RecurrenceType? _selectedRecurrenceType;
  int _recurrenceInterval = 1;
  List<int> _selectedDaysOfWeek = [];

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
      _selectedColor = widget.initialTask!.colorValue ?? 0xFF2196F3;

      // Инициализация параметров повторения
      if (_recurrence != null) {
        _selectedRecurrenceType = _recurrence!.type;
        _recurrenceInterval = _recurrence!.interval;
        _selectedDaysOfWeek = List.from(_recurrence!.daysOfWeek);
      }
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

            // НОВОЕ: Выбор повторения
            _buildRecurrenceSection(),
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

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Повторение", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<RecurrenceType>(
          value: _selectedRecurrenceType,
          items: RecurrenceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getRecurrenceTypeName(type)),
            );
          }).toList(),
          onChanged: (type) {
            setState(() {
              _selectedRecurrenceType = type;
              _updateRecurrence();
            });
          },
          decoration: const InputDecoration(
            labelText: "Тип повторения",
            border: OutlineInputBorder(),
          ),
        ),

        if (_selectedRecurrenceType != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text("Интервал:"),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _recurrenceInterval,
                items: [1, 2, 3, 4, 5, 6, 7].map((interval) {
                  return DropdownMenuItem(
                    value: interval,
                    child: Text('$interval'),
                  );
                }).toList(),
                onChanged: (interval) {
                  setState(() {
                    _recurrenceInterval = interval!;
                    _updateRecurrence();
                  });
                },
              ),
              const SizedBox(width: 16),
              Text(_getRecurrenceDescription()),
            ],
          ),
        ],

        if (_selectedRecurrenceType == RecurrenceType.custom) ...[
          const SizedBox(height: 12),
          const Text("Дни недели:"),
          Wrap(
            spacing: 8,
            children: [
              for (int day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(_getDayName(day)),
                  selected: _selectedDaysOfWeek.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDaysOfWeek.add(day);
                      } else {
                        _selectedDaysOfWeek.remove(day);
                      }
                      _updateRecurrence();
                    });
                  },
                ),
            ],
          ),
        ],

        if (_recurrence != null) ...[
          const SizedBox(height: 8),
          Text(
            "Текущее правило: ${_recurrence!.displayText}",
            style: TextStyle(color: Colors.green[700], fontSize: 12),
          ),
        ],
      ],
    );
  }

  String _getRecurrenceTypeName(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily: return 'Ежедневно';
      case RecurrenceType.weekly: return 'Еженедельно';
      case RecurrenceType.monthly: return 'Ежемесячно';
      case RecurrenceType.yearly: return 'Ежегодно';
      case RecurrenceType.custom: return 'По дням недели';
    }
  }

  String _getRecurrenceDescription() {
    if (_selectedRecurrenceType == null) return '';

    switch (_selectedRecurrenceType!) {
      case RecurrenceType.daily:
        return _recurrenceInterval == 1 ? 'каждый день' : 'каждые $_recurrenceInterval дней';
      case RecurrenceType.weekly:
        return _recurrenceInterval == 1 ? 'каждую неделю' : 'каждые $_recurrenceInterval недель';
      case RecurrenceType.monthly:
        return _recurrenceInterval == 1 ? 'каждый месяц' : 'каждые $_recurrenceInterval месяцев';
      case RecurrenceType.yearly:
        return _recurrenceInterval == 1 ? 'каждый год' : 'каждые $_recurrenceInterval лет';
      case RecurrenceType.custom:
        return 'по выбранным дням';
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Пн';
      case 2: return 'Вт';
      case 3: return 'Ср';
      case 4: return 'Чт';
      case 5: return 'Пт';
      case 6: return 'Сб';
      case 7: return 'Вс';
      default: return '';
    }
  }

  void _updateRecurrence() {
    if (_selectedRecurrenceType == null) {
      _recurrence = null;
      return;
    }

    _recurrence = Recurrence(
      type: _selectedRecurrenceType!,
      interval: _recurrenceInterval,
      daysOfWeek: _selectedRecurrenceType == RecurrenceType.custom
          ? _selectedDaysOfWeek
          : [],
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
                              _isColorPickerExpanded = false;
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
        Row(
          children: [
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
            const SizedBox(width: 12),
            const Text("Цвет задачи"),
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
      recurrence: _recurrence, // ← Теперь сохраняется повторение
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