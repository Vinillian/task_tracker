// lib/widgets/expandable_task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../services/task_service.dart';
import 'add_task_dialog.dart';
import 'task_progress_widget.dart';
import '../screens/task_detail_screen.dart';
import '../providers/task_provider.dart';

class ExpandableTaskCard extends ConsumerStatefulWidget {
  final Task task;
  final int taskIndex;
  final Function(Task) onTaskUpdated;
  final Function() onTaskDeleted;
  final TaskService taskService;
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
  ConsumerState<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends ConsumerState<ExpandableTaskCard> {
  bool _isExpanded = false;
  List<Task> _subTasks = [];

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

  void _openTaskDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          taskId: widget.task.id,
          taskService: widget.taskService,
        ),
      ),
    );
  }

  void _updateTaskSteps(int newCompletedSteps) {
    ref
        .read(tasksProvider.notifier)
        .updateTaskSteps(widget.task.id, newCompletedSteps);
  }

  void _manageTaskSteps() {
    final currentTask =
        ref.read(taskByIdProvider(widget.task.id)) ?? widget.task;
    int tempCompletedSteps = currentTask.completedSteps;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Управление прогрессом: ${currentTask.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Прогресс: $tempCompletedSteps/${currentTask.totalSteps}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: currentTask.totalSteps > 0
                        ? tempCompletedSteps / currentTask.totalSteps
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
                        onPressed: tempCompletedSteps < currentTask.totalSteps
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
                      hintText: 'Введите от 0 до ${currentTask.totalSteps}',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final newValue =
                          int.tryParse(value) ?? tempCompletedSteps;
                      setState(() {
                        tempCompletedSteps =
                            newValue.clamp(0, currentTask.totalSteps);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (currentTask.totalSteps > 1) ...[
                    const Text('Или используйте слайдер:'),
                    const SizedBox(height: 8),
                    Slider(
                      value: tempCompletedSteps.toDouble(),
                      min: 0,
                      max: currentTask.totalSteps.toDouble(),
                      divisions: currentTask.totalSteps,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSubTasks();
  }

  void _loadSubTasks() {
    _subTasks = widget.taskService.getSubTasks(widget.task.id);
  }

  @override
  void didUpdateWidget(ExpandableTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSubTasks();

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

  void _addSubTask() {
    final currentTask =
        ref.read(taskByIdProvider(widget.task.id)) ?? widget.task;
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskCreated: (String title, String description, TaskType type,
            int steps, String? parentId) {
          _createSubTask(
              title, description, type, steps, currentTask.projectId, parentId);
        },
        projectId: currentTask.projectId,
        parentId: currentTask.id,
      ),
    );
  }

  void _createSubTask(String title, String description, TaskType type,
      int totalSteps, String? projectId, String? parentId) {
    final currentTask =
        ref.read(taskByIdProvider(widget.task.id)) ?? widget.task;

    if (!widget.taskService.canAddSubTask(currentTask.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Достигнут максимальный уровень вложенности!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newSubTask = Task(
      id: '${currentTask.id}_${DateTime.now().millisecondsSinceEpoch}',
      parentId: parentId ?? currentTask.id,
      projectId: projectId ?? currentTask.projectId,
      title: title,
      description: description,
      isCompleted: false,
      type: type,
      totalSteps: totalSteps,
      completedSteps: 0,
      maxDepth: currentTask.maxDepth,
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
    widget.onTaskUpdated(widget.task);
  }

  void _deleteSubTask(String subTaskId) {
    widget.taskService.removeTask(subTaskId);
    _loadSubTasks();
    widget.onTaskUpdated(widget.task);
  }

  @override
  Widget build(BuildContext context) {
    final currentTask =
        ref.watch(taskByIdProvider(widget.task.id)) ?? widget.task;
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
                    TaskProgressWidget(
                      taskId: widget.task.id,
                      onTap: _openTaskDetail,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentTask.title,
                                  style: TextStyle(
                                    fontSize: 13 - (widget.level * 0.2),
                                    fontWeight: widget.level == 0
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    decoration: currentTask.isCompleted &&
                                            currentTask.type == TaskType.single
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
                          if (currentTask.description.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              currentTask.description,
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
                    SizedBox(
                      width: 90,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 0,
                        children: [
                          if (currentTask.type == TaskType.stepByStep)
                            IconButton(
                              icon: const Icon(Icons.play_circle_outline,
                                  color: Colors.purple, size: 18),
                              onPressed: _manageTaskSteps,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              tooltip: 'Управление шагами',
                            ),
                          if (widget.taskService.canAddSubTask(currentTask.id))
                            IconButton(
                              icon: const Icon(Icons.add, size: 14),
                              onPressed: _addSubTask,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                              tooltip: 'Добавить подзадачу',
                            ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new,
                                size: 14, color: Colors.blue),
                            onPressed: _openTaskDetail,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            tooltip: 'Открыть детали',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
