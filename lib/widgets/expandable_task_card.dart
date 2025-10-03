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

  @override
  Widget build(BuildContext context) {
    final hasSubTasks = widget.task.subTasks.isNotEmpty;
    final indent = widget.level * 20.0; // Отступ в зависимости от уровня

    return Card(
      margin: EdgeInsets.only(
        left: indent + 8, // Динамический отступ
        right: 8,
        top: 4,
        bottom: 4,
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная строка задачи
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Кнопка раскрытия (если есть подзадачи)
                if (hasSubTasks)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    onPressed: _toggleExpanded,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  )
                else
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),

                // Прогресс/чекбокс
                TaskProgressWidget(
                  task: widget.task,
                  onToggle: _toggleTaskCompletion,
                ),
                const SizedBox(width: 12),

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
                                fontSize: 16 - (widget.level * 0.5), // Уменьшаем шрифт для вложенных
                                fontWeight: widget.level == 0 ? FontWeight.w500 : FontWeight.w400,
                                decoration: widget.task.isCompleted && widget.task.type == TaskType.single
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: widget.task.isCompleted && widget.task.type == TaskType.single
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          // Индикатор подзадач
                          if (hasSubTasks)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.subdirectory_arrow_right, size: 12, color: Colors.blue),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.task.subTasks.length}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      if (widget.task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.task.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Информация о задаче
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.task.type == TaskType.stepByStep) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.shade100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.linear_scale, size: 10, color: Colors.purple),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.task.completedSteps}/${widget.task.totalSteps}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          if (widget.level > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade100),
                              ),
                              child: Text(
                                'уровень ${widget.level + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Кнопки действий
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.task.canAddSubTask)
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _addSubTask,
                        tooltip: 'Добавить подзадачу',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    if (widget.task.type == TaskType.stepByStep)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 18, color: Colors.purple),
                        onPressed: _manageTaskSteps,
                        tooltip: 'Управление шагами',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: _editTask,
                      tooltip: 'Редактировать задачу',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: widget.onTaskDeleted,
                      tooltip: 'Удалить задачу',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),

            // Раскрытая область с подзадачами
            if (_isExpanded && hasSubTasks) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...widget.task.subTasks.asMap().entries.map((entry) {
                final subTaskIndex = entry.key;
                final subTask = entry.value;

                return ExpandableTaskCard(
                  task: subTask,
                  taskIndex: subTaskIndex,
                  onTaskUpdated: (updatedSubTask) => _updateSubTask(subTaskIndex, updatedSubTask),
                  onTaskDeleted: () => _deleteSubTask(subTaskIndex),
                  level: widget.level + 1, // Увеличиваем уровень вложенности
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}