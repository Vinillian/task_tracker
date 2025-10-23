// widgets/expandable_task_card.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../services/task_service.dart';
import 'add_task_dialog.dart';
import 'edit_dialogs.dart';
import 'task_progress_widget.dart';

class ExpandableTaskCard extends StatefulWidget {
  final Task task;
  final int taskIndex;
  final Function(Task) onTaskUpdated;
  final Function() onTaskDeleted;
  final TaskService taskService; // ✅ ДОБАВЛЯЕМ TaskService
  final int level;
  final bool? forceExpanded;

  const ExpandableTaskCard({
    super.key,
    required this.task,
    required this.taskIndex,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
    required this.taskService,
    required this.level,
    this.forceExpanded,
  });

  @override
  State<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends State<ExpandableTaskCard> {
  bool _isExpanded = false;
  List<Task> _subTasks = []; // ✅ Кэшируем подзадачи

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.blue.shade400;
      case 1:
        return Colors.green.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.purple.shade400;
      default:
        return Colors.red.shade400;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSubTasks(); // ✅ Загружаем подзадачи при инициализации
  }

  void _loadSubTasks() {
    _subTasks = widget.taskService.getSubTasks(widget.task.id);
  }

  @override
  void didUpdateWidget(ExpandableTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSubTasks(); // ✅ Перезагружаем подзадачи при обновлении

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
        onTaskCreated: (String title, String description, TaskType type,
            int steps, String? parentId) {
          _createSubTask(
              title, description, type, steps, widget.task.projectId, parentId);
        },
        projectId: widget.task.projectId,
        parentId: widget.task.id,
      ),
    );
  }

  void _createSubTask(String title, String description, TaskType type,
      int totalSteps, String? projectId, String? parentId) {
    if (!widget.taskService.canAddSubTask(widget.task.id)) {
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
      parentId: parentId ?? widget.task.id,
      projectId: projectId ?? widget.task.projectId,
      title: title,
      description: description,
      isCompleted: false,
      type: type,
      totalSteps: totalSteps,
      completedSteps: 0,
      maxDepth: widget.task.maxDepth,
    );

    widget.taskService.addTask(newSubTask);
    _loadSubTasks();

    setState(() {
      _isExpanded = true;
    });

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

  void _updateSubTask(Task updatedSubTask) {
    widget.taskService.updateTask(updatedSubTask);
    widget.onTaskUpdated(widget.task); // Уведомляем родителя об изменении
  }

  void _deleteSubTask(String subTaskId) {
    widget.taskService.removeTask(subTaskId);
    _loadSubTasks(); // ✅ Перезагружаем подзадачи
    widget.onTaskUpdated(widget.task); // Уведомляем родителя об изменении
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
    final hasSubTasks = _subTasks.isNotEmpty;

    return Container(
      margin: widget.level == 0
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левая вертикальная полоса-индикатор уровня
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getLevelColor(widget.level),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Кнопка раскрытия подзадач
                    if (hasSubTasks)
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                        ),
                        onPressed: _toggleExpanded,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                      )
                    else
                      SizedBox(
                        width: 28,
                        child: Center(
                          child: Icon(
                            Icons.circle,
                            size: 3,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),

                    // Прогресс задачи
                    TaskProgressWidget(
                      task: widget.task,
                      onToggle: _toggleTaskCompletion,
                    ),
                    const SizedBox(width: 6),

                    // Текст задачи
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
                                    fontSize: 13 - (widget.level * 0.2),
                                    fontWeight: widget.level == 0
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    decoration: widget.task.isCompleted &&
                                            widget.task.type == TaskType.single
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasSubTasks)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_subTasks.length}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (widget.task.description.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.task.description,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Кнопки действий
                    SizedBox(
                      width: 120,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 0,
                        children: [
                          if (widget.taskService.canAddSubTask(widget.task.id))
                            IconButton(
                              icon: const Icon(Icons.add, size: 14),
                              onPressed: _addSubTask,
                              tooltip: 'Добавить подзадачу',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                            ),
                          if (widget.task.type == TaskType.stepByStep)
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline,
                                  color: Colors.purple, size: 22),
                              onPressed: _manageTaskSteps,
                              tooltip: 'Управление шагами',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 14, color: Colors.blue),
                            onPressed: _editTask,
                            tooltip: 'Редактировать',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 14, color: Colors.red),
                            onPressed: widget.onTaskDeleted,
                            tooltip: 'Удалить',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Подзадачи
          if (_isExpanded && hasSubTasks) ...[
            const SizedBox(height: 8),
            ..._subTasks.map((subTask) {
              return ExpandableTaskCard(
                task: subTask,
                taskIndex: 0,
                onTaskUpdated: _updateSubTask,
                onTaskDeleted: () => _deleteSubTask(subTask.id),
                taskService: widget.taskService,
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
