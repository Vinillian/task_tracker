// widgets/expandable_task_card.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import 'task_progress_widget.dart';
import 'add_task_dialog.dart';
import 'edit_dialogs.dart';

class ExpandableTaskCard extends StatefulWidget {
  final Task task;
  final int taskIndex;
  final Function(Task) onTaskUpdated;
  final Function() onTaskDeleted;
  final int level; // Уровень вложенности (0, 1, 2...)

  const ExpandableTaskCard({
    super.key,
    required this.task,
    required this.taskIndex,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
    required this.level,
  });

  @override
  State<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends State<ExpandableTaskCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _toggleTaskCompletion() {
    final updatedTask = widget.task.copyWith(isCompleted: !widget.task.isCompleted);
    widget.onTaskUpdated(updatedTask);
  }

  void _updateTaskSteps(int newCompletedSteps) {
    final updatedTask = widget.task.copyWith(completedSteps: newCompletedSteps);
    widget.onTaskUpdated(updatedTask);
  }

  void _editTask() {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(
        task: widget.task,
        onTaskUpdated: (String title, String description) {
          final updatedTask = widget.task.copyWith(
            title: title,
            description: description,
          );
          widget.onTaskUpdated(updatedTask);
        },
      ),
    );
  }

  void _addSubTask() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskCreated: (String title, String description, TaskType type, int steps) {
          _createSubTask(title, description, type, steps);
        },
      ),
    );
  }

  void _createSubTask(String title, String description, TaskType type, int totalSteps) {
    if (!widget.task.canAddSubTask) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Достигнут максимальный уровень вложенности!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newSubTask = Task(
      id: '${widget.task.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      isCompleted: false,
      type: type,
      totalSteps: totalSteps,
      completedSteps: 0,
      maxDepth: widget.task.maxDepth,
    );

    final updatedTask = widget.task.copyWith(
      subTasks: [...widget.task.subTasks, newSubTask],
    );

    widget.onTaskUpdated(updatedTask);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Подзадача "$title" добавлена!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateSubTask(int subTaskIndex, Task updatedSubTask) {
    final updatedSubTasks = List<Task>.from(widget.task.subTasks);
    updatedSubTasks[subTaskIndex] = updatedSubTask;
    final updatedTask = widget.task.copyWith(subTasks: updatedSubTasks);
    widget.onTaskUpdated(updatedTask);
  }

  void _deleteSubTask(int subTaskIndex) {
    final updatedSubTasks = List<Task>.from(widget.task.subTasks)..removeAt(subTaskIndex);
    final updatedTask = widget.task.copyWith(subTasks: updatedSubTasks);
    widget.onTaskUpdated(updatedTask);
  }

  void _manageTaskSteps() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Управление: ${widget.task.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Прогресс: ${widget.task.completedSteps}/${widget.task.totalSteps}'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: widget.task.progress),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: widget.task.completedSteps > 0
                          ? () {
                        _updateTaskSteps(widget.task.completedSteps - 1);
                        Navigator.pop(context);
                      }
                          : null,
                      child: const Text('-1'),
                    ),
                    ElevatedButton(
                      onPressed: widget.task.completedSteps < widget.task.totalSteps
                          ? () {
                        _updateTaskSteps(widget.task.completedSteps + 1);
                        Navigator.pop(context);
                      }
                          : null,
                      child: const Text('+1'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.task.totalSteps > 1) ...[
                  const Text('Или установите точное значение:'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: widget.task.completedSteps.toDouble(),
                          min: 0,
                          max: widget.task.totalSteps.toDouble(),
                          divisions: widget.task.totalSteps,
                          onChanged: (value) {
                            setState(() {
                              _updateTaskSteps(value.toInt());
                            });
                          },
                          onChangeEnd: (value) {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      ),
    );
  }

  // В методе build, обновим внешний вид карточки:
  @override
  Widget build(BuildContext context) {
    final hasSubTasks = widget.task.subTasks.isNotEmpty;
    final indent = widget.level * 16.0;

    return Card(
      margin: EdgeInsets.only(
        left: indent + 8,
        right: 8,
        top: 2, // ✅ Меньше отступов между задачами
        bottom: 2,
      ),
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(8), // ✅ Меньше padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная строка задачи
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Кнопка раскрытия
                if (hasSubTasks)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, // ✅ Меньше иконка
                    ),
                    onPressed: _toggleExpanded,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  )
                else
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Icon(
                        Icons.circle,
                        size: 4,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),

                // Прогресс/чекбокс
                TaskProgressWidget(
                  task: widget.task,
                  onToggle: _toggleTaskCompletion,
                ),
                const SizedBox(width: 8),

                // Содержимое задачи
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: TextStyle(
                                fontSize: 14 - (widget.level * 0.3), // ✅ Меньше шрифт
                                fontWeight: widget.level == 0 ? FontWeight.w500 : FontWeight.w400,
                                decoration: widget.task.isCompleted && widget.task.type == TaskType.single
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          // Индикатор подзадач
                          if (hasSubTasks)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.task.subTasks.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.task.description,
                          style: TextStyle(
                            fontSize: 11, // ✅ Меньше шрифт
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1, // ✅ Только одна строка
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // ✅ ГОРИЗОНТАЛЬНЫЕ КНОПКИ (вместо вертикальных)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.task.canAddSubTask)
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: _addSubTask,
                        tooltip: 'Добавить подзадачу',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    if (widget.task.type == TaskType.stepByStep)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 16, color: Colors.purple),
                        onPressed: _manageTaskSteps,
                        tooltip: 'Управление шагами',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                      onPressed: _editTask,
                      tooltip: 'Редактировать',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      onPressed: widget.onTaskDeleted,
                      tooltip: 'Удалить',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),

            // ✅ ВИЗУАЛИЗАЦИЯ ДЕРЕВА - линия вложенности
            if (widget.level > 0)
              Container(
                margin: const EdgeInsets.only(left: 40, top: 4),
                height: 1,
                color: Colors.grey.shade300,
              ),

            // Раскрытая область с подзадачами
            if (_isExpanded && hasSubTasks) ...[
              const SizedBox(height: 8),
              ...widget.task.subTasks.asMap().entries.map((entry) {
                final subTaskIndex = entry.key;
                final subTask = entry.value;

                return ExpandableTaskCard(
                  task: subTask,
                  taskIndex: subTaskIndex,
                  onTaskUpdated: (updatedSubTask) => _updateSubTask(subTaskIndex, updatedSubTask),
                  onTaskDeleted: () => _deleteSubTask(subTaskIndex),
                  level: widget.level + 1,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}