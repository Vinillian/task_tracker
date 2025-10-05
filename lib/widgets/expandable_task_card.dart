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

    // ✅ АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ СТАТУСА ПОДЗАДАЧ
    if (updatedTask.isCompleted && updatedTask.subTasks.isNotEmpty) {
      // Если задача завершена, завершаем все подзадачи
      final updatedSubTasks = _completeAllSubTasks(updatedTask.subTasks);
      final finalTask = updatedTask.copyWith(subTasks: updatedSubTasks);
      widget.onTaskUpdated(finalTask);
    } else {
      widget.onTaskUpdated(updatedTask);
    }
  }

  // ✅ РЕКУРСИВНОЕ ЗАВЕРШЕНИЕ ВСЕХ ПОДЗАДАЧ
  List<Task> _completeAllSubTasks(List<Task> subTasks) {
    return subTasks.map((subTask) {
      final completedSubTasks = _completeAllSubTasks(subTask.subTasks);
      return subTask.copyWith(
        isCompleted: true,
        subTasks: completedSubTasks,
        completedSteps: subTask.totalSteps, // Для stepByStep задач
      );
    }).toList();
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
      builder: (context) =>
          EditTaskDialog(
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
      builder: (context) =>
          AddTaskDialog(
            onTaskCreated:
                (String title, String description, TaskType type, int steps) {
              _createSubTask(title, description, type, steps);
            },
          ),
    );
  }

  void _createSubTask(String title, String description, TaskType type,
      int totalSteps) {
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
      id: '${widget.task.id}_${DateTime
          .now()
          .millisecondsSinceEpoch}',
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
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Управление прогрессом: ${widget.task.title}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Прогресс: $tempCompletedSteps/${widget.task
                            .totalSteps}',
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
                            onPressed: tempCompletedSteps <
                                widget.task.totalSteps
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

    return Card(
      margin: EdgeInsets.only(
        left: indent + 8,
        right: 8,
        top: 2,
        bottom: 2,
      ),
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
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
                      size: 18,
                    ),
                    onPressed: _toggleExpanded,
                    padding: EdgeInsets.zero,
                    constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
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
                TaskProgressWidget(
                  task: widget.task,
                  onToggle: _toggleTaskCompletion,
                ),
                const SizedBox(width: 8),
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
                                fontSize: 14 - (widget.level * 0.3),
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
                                  horizontal: 4, vertical: 1),
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
                            fontSize: 11,
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
                          _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                          size: 16,
                          color: Colors.green,
                        ),
                        onPressed: _toggleExpanded,
                        tooltip: _isExpanded
                            ? 'Свернуть подзадачи'
                            : 'Развернуть подзадачи',
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    if (widget.task.canAddSubTask)
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: _addSubTask,
                        tooltip: 'Добавить подзадачу',
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    if (widget.task.type == TaskType.stepByStep)
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline,
                            color: Colors.purple, size: 25),
                        onPressed: _manageTaskSteps,
                        tooltip: 'Управление шагами',
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    IconButton(
                      icon:
                      const Icon(Icons.edit, size: 16, color: Colors.blue),
                      onPressed: _editTask,
                      tooltip: 'Редактировать',
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon:
                      const Icon(Icons.delete, size: 16, color: Colors.red),
                      onPressed: widget.onTaskDeleted,
                      tooltip: 'Удалить',
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.level > 0)
              Container(
                margin:
                EdgeInsets.only(left: 40 + (widget.level - 1) * 16, top: 4),
                height: 1,
                color: Colors.grey.shade400,
              ),
            // ✅ РЕКУРСИВНОЕ ОТОБРАЖЕНИЕ ВСЕХ ПОДЗАДАЧ ПРИ РАСКРЫТИИ
            if (_isExpanded && hasSubTasks) ...[
              const SizedBox(height: 8),
              ...widget.task.subTasks
                  .asMap()
                  .entries
                  .map((entry) {
                final subTaskIndex = entry.key;
                final subTask = entry.value;

                return ExpandableTaskCard(
                  task: subTask,
                  taskIndex: subTaskIndex,
                  onTaskUpdated: (updatedSubTask) =>
                      _updateSubTask(subTaskIndex, updatedSubTask),
                  onTaskDeleted: () => _deleteSubTask(subTaskIndex),
                  level: widget.level + 1,
                  forceExpanded: widget
                      .forceExpanded, // ← ПЕРЕДАЕМ ГЛОБАЛЬНОЕ СОСТОЯНИЕ ВСЕМ ПОДЗАДАЧАМ
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
