import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../models/project.dart';
import '../services/task_service.dart';

class DetailedCompletionDialog extends StatefulWidget {
  final dynamic item;
  final Project? project;
  final Task? task;
  final Stage? stage;

  const DetailedCompletionDialog({
    super.key,
    required this.item,
    this.project,
    this.task,
    this.stage,
  });

  @override
  State<DetailedCompletionDialog> createState() => _DetailedCompletionDialogState();
}

class _DetailedCompletionDialogState extends State<DetailedCompletionDialog> {
  late dynamic _currentItem;
  late Project? _project;
  late Task? _task;
  late Stage? _stage;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _project = widget.project;
    _task = widget.task;
    _stage = widget.stage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getDialogTitle()),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _completeItem,
          child: const Text('Завершить'),
        ),
      ],
    );
  }

  String _getDialogTitle() {
    if (_currentItem is Task) return 'Выполнение задачи: ${_currentItem.name}';
    if (_currentItem is Stage) return 'Выполнение этапа: ${_currentItem.name}';
    if (_currentItem is custom_step.Step) return 'Выполнение шага: ${_currentItem.name}';
    return 'Выполнение';
  }

  Widget _buildContent() {
    if (_currentItem is Task) {
      return _buildTaskContent(_currentItem as Task);
    } else if (_currentItem is Stage) {
      return _buildStageContent(_currentItem as Stage);
    } else if (_currentItem is custom_step.Step) {
      return _buildStepContent(_currentItem as custom_step.Step);
    }

    return const Text('Неизвестный тип элемента');
  }

  Widget _buildTaskContent(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Проект: ${_project?.name ?? "Неизвестно"}'),
        const SizedBox(height: 16),

        if (task.description != null) ...[
          Text('Описание: ${task.description}'),
          const SizedBox(height: 8),
        ],

        if (task.taskType == "singleStep")
          _buildSingleStepCompletion(task),

        if (task.taskType == "stepByStep")
          _buildStepByStepCompletion(task),

        if (task.stages.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Этапы:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...task.stages.map((stage) => _buildStageTile(stage)).toList(),
        ],
      ],
    );
  }

  Widget _buildStageContent(Stage stage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Проект: ${_project?.name ?? "Неизвестно"}'),
        Text('Задача: ${_task?.name ?? "Неизвестно"}'),
        const SizedBox(height: 16),

        if (stage.stageType == "singleStep")
          _buildSingleStepCompletion(stage),

        if (stage.stageType == "stepByStep")
          _buildStepByStepCompletion(stage),

        if (stage.steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Шаги:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...stage.steps.map((step) => _buildStepTile(step)).toList(),
        ],
      ],
    );
  }

  Widget _buildStepContent(custom_step.Step step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Проект: ${_project?.name ?? "Неизвестно"}'),
        Text('Задача: ${_task?.name ?? "Неизвестно"}'),
        Text('Этап: ${_stage?.name ?? "Неизвестно"}'),
        const SizedBox(height: 16),

        if (step.stepType == "singleStep")
          CheckboxListTile(
            title: const Text('Отметить как выполненный'),
            value: step.isCompleted,
            onChanged: (value) {
              setState(() {
                _currentItem = TaskService.toggleStepCompletion(step);
              });
            },
          ),

        if (step.stepType == "stepByStep")
          _buildProgressInput(step),
      ],
    );
  }

  Widget _buildSingleStepCompletion(dynamic item) {
    return CheckboxListTile(
      title: const Text('Отметить как выполненный'),
      value: item.isCompleted,
      onChanged: (value) {
        setState(() {
          if (item is Task) {
            _currentItem = TaskService.toggleTaskCompletion(item);
          } else if (item is Stage) {
            _currentItem = TaskService.toggleStageCompletion(item);
          } else if (item is custom_step.Step) {
            _currentItem = TaskService.toggleStepCompletion(item);
          }
        });
      },
    );
  }

  Widget _buildStepByStepCompletion(dynamic item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Прогресс: ${item.completedSteps}/${item.totalSteps}'),
        const SizedBox(height: 8),
        Slider(
          value: item.completedSteps.toDouble(),
          min: 0,
          max: item.totalSteps.toDouble(),
          divisions: item.totalSteps,
          label: item.completedSteps.toString(),
          onChanged: (value) {
            setState(() {
              if (item is Task) {
                _currentItem = TaskService.addProgressToTask(item, value.toInt() - item.completedSteps);
              } else if (item is Stage) {
                _currentItem = TaskService.addProgressToStage(item, value.toInt() - item.completedSteps);
              } else if (item is custom_step.Step) {
                _currentItem = TaskService.addProgressToStep(item, value.toInt() - item.completedSteps);
              }
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () => _addProgress(-1),
              child: const Text('-1'),
            ),
            ElevatedButton(
              onPressed: () => _addProgress(1),
              child: const Text('+1'),
            ),
            ElevatedButton(
              onPressed: () => _addProgress(5),
              child: const Text('+5'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressInput(dynamic item) {
    return Column(
      children: [
        Text('Добавить прогресс (текущий: ${item.completedSteps}/${item.totalSteps})'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Количество шагов',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final steps = int.tryParse(value) ?? 0;
                  if (steps > 0) {
                    setState(() {
                      if (item is Task) {
                        _currentItem = TaskService.addProgressToTask(item, steps);
                      } else if (item is Stage) {
                        _currentItem = TaskService.addProgressToStage(item, steps);
                      } else if (item is custom_step.Step) {
                        _currentItem = TaskService.addProgressToStep(item, steps);
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStageTile(Stage stage) {
    return ListTile(
      title: Text(stage.name),
      subtitle: Text('${stage.completedSteps}/${stage.totalSteps} шагов'),
      trailing: stage.stageType == "singleStep"
          ? Checkbox(
        value: stage.isCompleted,
        onChanged: (value) {
          setState(() {
            final updatedStage = TaskService.toggleStageCompletion(stage);
            // Обновляем stage в текущей task
            if (_currentItem is Task) {
              final task = _currentItem as Task;
              final stageIndex = task.stages.indexOf(stage);
              if (stageIndex != -1) {
                final updatedStages = List<Stage>.from(task.stages);
                updatedStages[stageIndex] = updatedStage;
                _currentItem = Task(
                  name: task.name,
                  completedSteps: task.completedSteps,
                  totalSteps: task.totalSteps,
                  stages: updatedStages,
                  taskType: task.taskType,
                  recurrence: task.recurrence,
                  dueDate: task.dueDate,
                  isCompleted: task.isCompleted,
                  description: task.description,
                  plannedDate: task.plannedDate,
                );
              }
            }
          });
        },
      )
          : null,
      onTap: () {
        setState(() {
          _currentItem = stage;
          _stage = stage;
        });
      },
    );
  }

  Widget _buildStepTile(custom_step.Step step) {
    return ListTile(
      title: Text(step.name),
      subtitle: Text('${step.completedSteps}/${step.totalSteps} шагов'),
      trailing: step.stepType == "singleStep"
          ? Checkbox(
        value: step.isCompleted,
        onChanged: (value) {
          setState(() {
            final updatedStep = TaskService.toggleStepCompletion(step);
            // Обновляем step в текущем stage
            if (_currentItem is Stage) {
              final stage = _currentItem as Stage;
              final stepIndex = stage.steps.indexOf(step);
              if (stepIndex != -1) {
                final updatedSteps = List<custom_step.Step>.from(stage.steps);
                updatedSteps[stepIndex] = updatedStep;
                _currentItem = Stage(
                  name: stage.name,
                  completedSteps: stage.completedSteps,
                  totalSteps: stage.totalSteps,
                  stageType: stage.stageType,
                  isCompleted: stage.isCompleted,
                  steps: updatedSteps,
                  plannedDate: stage.plannedDate,
                  recurrence: stage.recurrence,
                );
              }
            }
          });
        },
      )
          : null,
      onTap: () {
        setState(() {
          _currentItem = step;
        });
      },
    );
  }

  void _addProgress(int steps) {
    setState(() {
      if (_currentItem is Task) {
        _currentItem = TaskService.addProgressToTask(_currentItem, steps);
      } else if (_currentItem is Stage) {
        _currentItem = TaskService.addProgressToStage(_currentItem, steps);
      } else if (_currentItem is custom_step.Step) {
        _currentItem = TaskService.addProgressToStep(_currentItem, steps);
      }
    });
  }

  void _completeItem() {
    // Здесь будет логика сохранения изменений
    Navigator.of(context).pop(_currentItem);
  }
}