import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class ProjectWidgets {
  static double calculateSubtaskProgress(Subtask subtask) {
    return subtask.totalSteps > 0 ? subtask.completedSteps / subtask.totalSteps : 0;
  }

  static double calculateTaskProgress(Task task) {
    return task.totalSteps > 0 ? task.completedSteps / task.totalSteps : 0;
  }

  static double calculateProjectProgress(Project project) {
    int totalSteps = 0;
    int completedSteps = 0;

    for (final task in project.tasks) {
      totalSteps += task.totalSteps;
      completedSteps += task.completedSteps;

      for (final subtask in task.subtasks) {
        totalSteps += subtask.totalSteps;
        completedSteps += subtask.completedSteps;
      }
    }

    return totalSteps > 0 ? completedSteps / totalSteps : 0;
  }

  static int getTotalStepsForTask(Task task) {
    int total = task.totalSteps;
    for (final subtask in task.subtasks) {
      total += subtask.totalSteps;
    }
    return total;
  }

  static int getCompletedStepsForTask(Task task) {
    int completed = task.completedSteps;
    for (final subtask in task.subtasks) {
      completed += subtask.completedSteps;
    }
    return completed;
  }

  static Color getProgressColor(double progress) {
    if (progress == 1.0) return Colors.green;
    if (progress > 0.7) return Colors.orange;
    return Colors.red;
  }

  static String getProjectStepsInfo(Project project) {
    int completed = 0;
    int total = 0;

    for (final task in project.tasks) {
      completed += task.completedSteps;
      total += task.totalSteps;
      for (final subtask in task.subtasks) {
        completed += subtask.completedSteps;
        total += subtask.totalSteps;
      }
    }

    return '$completed/$total';
  }

  static Widget buildProjectItem({
    required Project project,
    required int projectIndex,
    required Map<int, bool> showTaskInput,
    required Map<String, bool> showSubtaskInput,
    required Function(int, bool) onShowTaskInputChanged,
    required Function(String, bool) onShowSubtaskInputChanged,
    required TextEditingController Function(int) getTaskNameController,
    required TextEditingController Function(int) getTaskStepsController,
    required TextEditingController Function(int, int) getSubtaskNameController,
    required TextEditingController Function(int, int) getSubtaskStepsController,
    required Function(int) onAddTask,
    required Function(int, int) onAddSubtask,
    required Function(int, int, int) onAddIncrementalProgress,
  }) {
    final progress = calculateProjectProgress(project);

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: CircularProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(progress)),
        ),
        title: Text(project.name),
        subtitle: Text(
          '${(progress * 100).toStringAsFixed(0)}% · ${getProjectStepsInfo(project)}',
        ),
        children: [_buildProjectContent(
          project: project,
          projectIndex: projectIndex,
          showTaskInput: showTaskInput,
          showSubtaskInput: showSubtaskInput,
          onShowTaskInputChanged: onShowTaskInputChanged,
          onShowSubtaskInputChanged: onShowSubtaskInputChanged,
          getTaskNameController: getTaskNameController,
          getTaskStepsController: getTaskStepsController,
          getSubtaskNameController: getSubtaskNameController,
          getSubtaskStepsController: getSubtaskStepsController,
          onAddTask: onAddTask,
          onAddSubtask: onAddSubtask,
          onAddIncrementalProgress: onAddIncrementalProgress,
        )],
      ),
    );
  }

  static Widget _buildProjectContent({
    required Project project,
    required int projectIndex,
    required Map<int, bool> showTaskInput,
    required Map<String, bool> showSubtaskInput,
    required Function(int, bool) onShowTaskInputChanged,
    required Function(String, bool) onShowSubtaskInputChanged,
    required TextEditingController Function(int) getTaskNameController,
    required TextEditingController Function(int) getTaskStepsController,
    required TextEditingController Function(int, int) getSubtaskNameController,
    required TextEditingController Function(int, int) getSubtaskStepsController,
    required Function(int) onAddTask,
    required Function(int, int) onAddSubtask,
    required Function(int, int, int) onAddIncrementalProgress,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (!(showTaskInput[projectIndex] ?? false))
                ElevatedButton(
                  onPressed: () => onShowTaskInputChanged(projectIndex, true),
                  child: const Text('+ Новая задача'),
                ),
            ],
          ),
        ),

        if (showTaskInput[projectIndex] ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: getTaskNameController(projectIndex),
                    decoration: const InputDecoration(
                      hintText: 'Название задачи',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: getTaskStepsController(projectIndex),
                    decoration: const InputDecoration(
                      hintText: 'Шаги',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onAddTask(projectIndex),
                  child: const Text('Добавить'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => onShowTaskInputChanged(projectIndex, false),
                ),
              ],
            ),
          ),

        ...project.tasks.asMap().entries.map((entry) {
          final taskIndex = entry.key;
          final task = entry.value;
          final taskProgress = calculateTaskProgress(task);

          return Card(
            margin: const EdgeInsets.all(8),
            color: Colors.grey[50],
            child: ExpansionTile(
              leading: CircularProgressIndicator(
                value: taskProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(taskProgress)),
              ),
              title: Text(task.name),
              subtitle: Text('${task.completedSteps}/${task.totalSteps}'),
              trailing: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () => onAddIncrementalProgress(projectIndex, taskIndex, -1),
              ),
              children: [_buildTaskContent(
                task: task,
                projectIndex: projectIndex,
                taskIndex: taskIndex,
                showSubtaskInput: showSubtaskInput,
                onShowSubtaskInputChanged: onShowSubtaskInputChanged,
                getSubtaskNameController: getSubtaskNameController,
                getSubtaskStepsController: getSubtaskStepsController,
                onAddSubtask: onAddSubtask,
                onAddIncrementalProgress: onAddIncrementalProgress,
              )],
            ),
          );
        }),
      ],
    );
  }

  static Widget _buildTaskContent({
    required Task task,
    required int projectIndex,
    required int taskIndex,
    required Map<String, bool> showSubtaskInput,
    required Function(String, bool) onShowSubtaskInputChanged,
    required TextEditingController Function(int, int) getSubtaskNameController,
    required TextEditingController Function(int, int) getSubtaskStepsController,
    required Function(int, int) onAddSubtask,
    required Function(int, int, int) onAddIncrementalProgress,
  }) {
    final subtaskKey = 'p${projectIndex}t$taskIndex';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (!(showSubtaskInput[subtaskKey] ?? false))
                ElevatedButton(
                  onPressed: () => onShowSubtaskInputChanged(subtaskKey, true),
                  child: const Text('+ Новая подзадача'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
        ),

        if (showSubtaskInput[subtaskKey] ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: getSubtaskNameController(projectIndex, taskIndex),
                    decoration: const InputDecoration(
                      hintText: 'Название подзадачи',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: getSubtaskStepsController(projectIndex, taskIndex),
                    decoration: const InputDecoration(
                      hintText: 'Шаги',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onAddSubtask(projectIndex, taskIndex),
                  child: const Text('Добавить'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => onShowSubtaskInputChanged(subtaskKey, false),
                ),
              ],
            ),
          ),

        ...task.subtasks.asMap().entries.map((entry) {
          final subtaskIndex = entry.key;
          final subtask = entry.value;
          final subtaskProgress = calculateSubtaskProgress(subtask);

          return ListTile(
            leading: CircularProgressIndicator(
              value: subtaskProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(getProgressColor(subtaskProgress)),
            ),
            title: Text(subtask.name),
            subtitle: Text('${subtask.completedSteps}/${subtask.totalSteps}'),
            trailing: IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: () => onAddIncrementalProgress(projectIndex, taskIndex, subtaskIndex),
            ),
          );
        }),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Общий прогресс: ${getCompletedStepsForTask(task)}/${getTotalStepsForTask(task)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}