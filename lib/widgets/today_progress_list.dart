// lib/widgets/today_progress_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/widgets/task_list_item.dart';

class TodayProgressList extends StatelessWidget {
  const TodayProgressList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Project>>(
      stream: Provider.of<TaskService>(context).watchProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Нет задач на сегодня'),
          );
        }

        final todayTasks = <Task>[];
        final today = DateTime.now();

        // Collect all tasks for today from all projects
        for (final project in snapshot.data!) {
          final projectTasks = _getTodayTasks(project, today);
          todayTasks.addAll(projectTasks);
        }

        if (todayTasks.isEmpty) {
          return const Center(
            child: Text('Нет задач на сегодня'),
          );
        }

        return ListView.builder(
          itemCount: todayTasks.length,
          itemBuilder: (context, index) {
            final task = todayTasks[index];
            return TaskListItem(
              task: task,
              onTap: () => _showTaskDetails(context, task),
            );
          },
        );
      },
    );
  }

  List<Task> _getTodayTasks(Project project, DateTime today) {
    final todayTasks = <Task>[];

    void checkTask(Task task) {
      if (_isTaskForToday(task, today)) {
        todayTasks.add(task);
      }

      // Recursively check subtasks
      for (final subTask in task.subTasks) {
        checkTask(subTask);
      }
    }

    for (final task in project.tasks) {
      checkTask(task);
    }

    return todayTasks;
  }

  bool _isTaskForToday(Task task, DateTime today) {
    if (task.dueDate == null) return false;

    final taskDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    final todayDate = DateTime(today.year, today.month, today.day);

    return taskDate == todayDate && !task.isCompleted;
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description.isNotEmpty)
                Text(task.description),
              const SizedBox(height: 16),
              Text('Приоритет: ${_getPriorityText(task.priority)}'),
              if (task.dueDate != null)
                Text('Срок: ${_formatDate(task.dueDate!)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1: return 'Низкий';
      case 2: return 'Средний';
      case 3: return 'Высокий';
      default: return 'Обычный';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}