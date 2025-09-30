import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_type.dart';

class TaskEditDialog extends StatefulWidget {
  final String projectId;
  final Task? task;
  final Task? parentTask;
  final int nestingLevel;

  const TaskEditDialog({
    Key? key,
    required this.projectId,
    this.task,
    this.parentTask,
    required this.nestingLevel,
  }) : super(key: key);

  @override
  _TaskEditDialogState createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();

  TaskType _selectedType = TaskType.single;
  int _selectedPriority = 1;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();

    // Заполняем поля если редактируем существующую задачу
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedType = widget.task!.type;
      _selectedPriority = widget.task!.priority;
      _selectedDueDate = widget.task!.dueDate;
      _estimatedMinutesController.text = widget.task!.estimatedMinutes.toString();
    } else {
      // Для новой задачи устанавливаем тип по умолчанию
      _selectedType = widget.nestingLevel > 0 ? TaskType.single : TaskType.single;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final canChangeType = !isEditing || widget.task!.subtasks.isEmpty;

    return AlertDialog(
      title: Text(isEditing ? 'Редактировать задачу' :
      widget.parentTask != null ? 'Добавить подзадачу' : 'Новая задача'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Индикатор вложенности
              if (widget.nestingLevel > 0) ...[
                _buildNestingInfo(),
                SizedBox(height: 16),
              ],

              // Поле названия
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Название задачи',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название задачи';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Поле описания
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Тип задачи (только если можно менять)
              if (canChangeType) ...[
                _buildTaskTypeSelector(),
                SizedBox(height: 16),
              ] else ...[
                _buildTaskTypeDisplay(),
                SizedBox(height: 16),
              ],

              // Приоритет
              _buildPrioritySelector(),
              SizedBox(height: 16),

              // Дата выполнения
              _buildDueDateSelector(),
              SizedBox(height: 16),

              // Оценка времени
              TextFormField(
                controller: _estimatedMinutesController,
                decoration: InputDecoration(
                  labelText: 'Оценка времени (минуты)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final minutes = int.tryParse(value);
                    if (minutes == null || minutes < 0) {
                      return 'Введите корректное число';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }

  Widget _buildNestingInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.parentTask != null
                  ? 'Подзадача для: ${widget.parentTask!.title}'
                  : 'Уровень вложенности: ${widget.nestingLevel + 1}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип задачи',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<TaskType>(
          value: _selectedType,
          items: TaskType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  _getTaskTypeIcon(type),
                  SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (TaskType? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedType = newValue;
              });
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        SizedBox(height: 4),
        Text(
          _selectedType.description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTaskTypeDisplay() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _getTaskTypeIcon(widget.task!.type),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тип задачи: ${widget.task!.type.displayName}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Нельзя изменить тип задачи с подзадачами',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Приоритет',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedPriority,
          items: [1, 2, 3, 4, 5].map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: _getPriorityColor(priority),
                  ),
                  SizedBox(width: 8),
                  Text('Приоритет $priority'),
                ],
              ),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPriority = newValue;
              });
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Срок выполнения',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _selectDueDate,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  _selectedDueDate != null
                      ? '${_selectedDueDate!.day}.${_selectedDueDate!.month}.${_selectedDueDate!.year}'
                      : 'Выберите дату (необязательно)',
                  style: TextStyle(
                    color: _selectedDueDate != null ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedDueDate != null) ...[
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedDueDate = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
            ),
            child: Text('Очистить дату'),
          ),
        ],
      ],
    );
  }

  void _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = _createTaskFromForm();
      Navigator.of(context).pop(task);
    }
  }

  Task _createTaskFromForm() {
    final now = DateTime.now();

    // Если редактируем существующую задачу
    if (widget.task != null) {
      return widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        estimatedMinutes: int.tryParse(_estimatedMinutesController.text) ?? 0,
      );
    }

    // Если создаем новую задачу
    return Task(
      id: 'task_${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isCompleted: false,
      completedSubtasks: 0,
      totalSubtasks: 0,
      subtasks: [],
      type: _selectedType,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      estimatedMinutes: int.tryParse(_estimatedMinutesController.text) ?? 0,
      projectId: widget.projectId,
      nestingLevel: widget.nestingLevel,
      createdAt: now,
    );
  }

  Icon _getTaskTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.single:
        return Icon(Icons.check_circle_outline, color: Colors.green);
      case TaskType.multiStep:
        return Icon(Icons.list_alt, color: Colors.blue);
      case TaskType.recurring:
        return Icon(Icons.repeat, color: Colors.orange);
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}