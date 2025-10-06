// widgets/expandable_task_card.dart
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_type.dart';
import 'add_task_dialog.dart';
import 'edit_dialogs.dart';
import 'task_progress_widget.dart';

class ExpandableTaskCard extends StatefulWidget {
  final Task task;
  final int taskIndex;
  final Function(Task) onTaskUpdated;
  final Function() onTaskDeleted;
  final int level;
  final bool? forceExpanded;

  const ExpandableTaskCard({
    super.key,
    required this.task,
    required this.taskIndex,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
    required this.level,
    this.forceExpanded,
  });

  @override
  State<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends State<ExpandableTaskCard> {
  bool _isExpanded = false;

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue.shade300;
      case 2:
        return Colors.green.shade300;
      case 3:
        return Colors.orange.shade300;
      case 4:
        return Colors.purple.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  void didUpdateWidget(ExpandableTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ ИСПРАВЛЕНО: Синхронизация ТОЛЬКО если forceExpanded явно указан
    // и он изменился по сравнению с предыдущим значением
    if (widget.forceExpanded != null &&
        oldWidget.forceExpanded != widget.forceExpanded) {
      setState(() {
        _isExpanded = widget.forceExpanded!;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _toggleTaskCompletion() {
    final updatedTask =
        widget.task.copyWith(isCompleted: !widget.task.isCompleted);

    // ✅ ИСПРАВЛЕНО: Прогресс родительских задач НЕ влияет на дочерние
    // Каждая задача управляется независимо
    widget.onTaskUpdated(updatedTask);
  }


  void _updateTaskSteps(int newCompletedSteps) {
    final updatedTask = widget.task.copyWith(completedSteps: newCompletedSteps);

    // ✅ АВТОМАТИЧЕСКОЕ ЗАВЕРШЕНИЕ ПРИ 100% ПРОГРЕССЕ
    if (newCompletedSteps >= widget.task.totalSteps &&
        widget.task.totalSteps > 0) {
      updatedTask.isCompleted = true;
    }

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
        onTaskCreated:
            (String title, String description, TaskType type, int steps) {
          _createSubTask(title, description, type, steps);
        },
      ),
    );
  }

  void _createSubTask(
      String title, String description, TaskType type, int totalSteps) {
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

    // ✅ ИСПРАВЛЕНО: Автоматическое раскрытие ТОЛЬКО текущей задачи
    // НЕ зависит от глобального состояния "развернуть все"
    setState(() {
      _isExpanded = true; // Всегда раскрываем при добавлении подзадачи
    });

    widget.onTaskUpdated(updatedTask);

    // ✅ АВТОПРОКРУТКА К НОВОЙ ПОДЗАДАЧЕ
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final scrollController = PrimaryScrollController.of(context);
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }

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

    // ✅ АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ СТАТУСА РОДИТЕЛЬСКОЙ ЗАДАЧИ
    updatedTask.updateCompletionStatus();

    widget.onTaskUpdated(updatedTask);
  }

  void _deleteSubTask(int subTaskIndex) {
    final updatedSubTasks = List<Task>.from(widget.task.subTasks)
      ..removeAt(subTaskIndex);
    final updatedTask = widget.task.copyWith(subTasks: updatedSubTasks);
    widget.onTaskUpdated(updatedTask);
  }

  void _manageTaskSteps() {
    int tempCompletedSteps = widget.task.completedSteps;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Управление прогрессом: ${widget.task.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Прогресс: $tempCompletedSteps/${widget.task.totalSteps}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: widget.task.totalSteps > 0
                        ? tempCompletedSteps / widget.task.totalSteps
                        : 0.0,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Сброс'),
                        onPressed: () {
                          setState(() {
                            tempCompletedSteps = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: const Text('1'),
                        onPressed: tempCompletedSteps > 0
                            ? () {
                                setState(() {
                                  tempCompletedSteps--;
                                });
                              }
                            : null,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('1'),
                        onPressed: tempCompletedSteps < widget.task.totalSteps
                            ? () {
                                setState(() {
                                  tempCompletedSteps++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Установить точное значение',
                      hintText: 'Введите от 0 до ${widget.task.totalSteps}',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final newValue =
                          int.tryParse(value) ?? tempCompletedSteps;
                      setState(() {
                        tempCompletedSteps =
                            newValue.clamp(0, widget.task.totalSteps);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (widget.task.totalSteps > 1) ...[
                    const Text('Или используйте слайдер:'),
                    const SizedBox(height: 8),
                    Slider(
                      value: tempCompletedSteps.toDouble(),
                      min: 0,
                      max: widget.task.totalSteps.toDouble(),
                      divisions: widget.task.totalSteps,
                      label: '$tempCompletedSteps',
                      onChanged: (value) {
                        setState(() {
                          tempCompletedSteps = value.toInt();
                        });
                      },
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
                  _updateTaskSteps(tempCompletedSteps);
                  Navigator.pop(context);
                },
                child: const Text('Сохранить'),
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
    final indent = widget.level * 16.0;

    return Container(
      margin: EdgeInsets.only(
        left: indent + 6, // Уменьшил с 8 до 6
        right: 6, // Уменьшил с 8 до 6
        top: 1, // Уменьшил с 2 до 1
        bottom: 1, // Уменьшил с 2 до 1
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ КОМПАКТНЫЙ КОНТЕЙНЕР БЕЗ ГРАНИЦ
          Container(
            padding: const EdgeInsets.all(8), // Уменьшил с 12 до 8
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasSubTasks)
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16, // Уменьшил с 18 до 16
                        ),
                        onPressed: _toggleExpanded,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 28, minHeight: 28), // Уменьшил
                      )
                    else
                      SizedBox(
                        width: 28, // Уменьшил с 32 до 28
                        child: Center(
                          child: Icon(
                            Icons.circle,
                            size: 3, // Уменьшил с 4 до 3
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                    TaskProgressWidget(
                      task: widget.task,
                      onToggle: _toggleTaskCompletion,
                    ),
                    const SizedBox(width: 6), // Уменьшил с 8 до 6

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
                                    fontSize: 13 -
                                        (widget.level *
                                            0.2), // Уменьшил базовый размер
                                    fontWeight: widget.level == 0
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    decoration: widget.task.isCompleted &&
                                            widget.task.type == TaskType.single
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                              if (hasSubTasks)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 1), // Уменьшил
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${widget.task.subTasks.length}',
                                    style: const TextStyle(
                                      fontSize: 9, // Уменьшил с 10 до 9
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (widget.task.description.isNotEmpty) ...[
                            const SizedBox(height: 1), // Уменьшил с 2 до 1
                            Text(
                              widget.task.description,
                              style: TextStyle(
                                fontSize: 10, // Уменьшил с 11 до 10
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasSubTasks)
                          IconButton(
                            icon: Icon(
                              _isExpanded
                                  ? Icons.unfold_less
                                  : Icons.unfold_more,
                              size: 14, // Уменьшил с 16 до 14
                              color: Colors.green,
                            ),
                            onPressed: _toggleExpanded,
                            tooltip: _isExpanded
                                ? 'Свернуть подзадачи'
                                : 'Развернуть подзадачи',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28), // Уменьшил
                          ),
                        if (widget.task.canAddSubTask)
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            // Уменьшил с 16 до 14
                            onPressed: _addSubTask,
                            tooltip: 'Добавить подзадачу',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28), // Уменьшил
                          ),
                        if (widget.task.type == TaskType.stepByStep)
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline,
                                color: Colors.purple, size: 22),
                            // Уменьшил с 25 до 22
                            onPressed: _manageTaskSteps,
                            tooltip: 'Управление шагами',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36), // Уменьшил
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 14, color: Colors.blue),
                          // Уменьшил
                          onPressed: _editTask,
                          tooltip: 'Редактировать',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28), // Уменьшил
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 14, color: Colors.red),
                          // Уменьшил
                          onPressed: widget.onTaskDeleted,
                          tooltip: 'Удалить',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28), // Уменьшил
                        ),
                      ],
                    ),
                  ],
                ),

                // ✅ КОМПАКТНОЕ ПОДЧЕРКИВАНИЕ
                Container(
                  margin: const EdgeInsets.only(top: 6), // Уменьшил с 8 до 6
                  height: widget.level == 0 ? 2 : 1, // Уменьшил толщину
                  decoration: BoxDecoration(
                    gradient: widget.level == 0
                        ? LinearGradient(
                            colors: [
                              Colors.blue.shade300,
                              Colors.blue.shade100,
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade200,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),

          // ✅ РЕКУРСИВНОЕ ОТОБРАЖЕНИЕ ВСЕХ ПОДЗАДАЧ ПРИ РАСКРЫТИИ
          if (_isExpanded && hasSubTasks) ...[
            const SizedBox(height: 8),
            ...widget.task.subTasks.asMap().entries.map((entry) {
              final subTaskIndex = entry.key;
              final subTask = entry.value;

              return ExpandableTaskCard(
                task: subTask,
                taskIndex: subTaskIndex,
                onTaskUpdated: (updatedSubTask) =>
                    _updateSubTask(subTaskIndex, updatedSubTask),
                onTaskDeleted: () => _deleteSubTask(subTaskIndex),
                level: widget.level + 1,
                forceExpanded: widget.forceExpanded,
              );
            }),
          ],
        ],
      ),
    );
  }
}
