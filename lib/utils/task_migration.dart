import '../models/task.dart';
import '../models/project.dart';
import '../models/stage.dart' as old_models; // Старые модели
import '../models/step.dart' as old_models;

class TaskMigration {
  // Миграция проекта со старыми Stage/Step на новые Task
  static Project migrateProject(Project oldProject) {
    final migratedTasks = <Task>[];

    for (final oldTask in oldProject.tasks) {
      final migratedTask = _migrateTask(oldTask);
      migratedTasks.add(migratedTask);
    }

    return oldProject.copyWith(tasks: migratedTasks);
  }

  // Миграция одной задачи
  static Task _migrateTask(old_models.Task oldTask) {
    final subtasks = <Task>[];

    // Конвертируем stages в подзадачи первого уровня
    for (final oldStage in oldTask.stages) {
      final stageTask = _convertStageToTask(oldStage, oldTask.id, 0);
      subtasks.add(stageTask);
    }

    return Task(
      id: oldTask.id,
      title: oldTask.title,
      description: oldTask.description,
      isCompleted: oldTask.isCompleted,
      completedSubtasks: _calculateCompletedSubtasks(subtasks),
      totalSubtasks: _calculateTotalSubtasks(subtasks),
      subtasks: subtasks,
      type: _convertTaskType(oldTask.type),
      priority: oldTask.priority,
      dueDate: oldTask.dueDate,
      estimatedMinutes: oldTask.estimatedMinutes,
      projectId: oldTask.projectId,
      nestingLevel: 0,
      createdAt: oldTask.createdAt,
      completedAt: oldTask.completedAt,
    );
  }

  // Конвертация Stage в Task
  static Task _convertStageToTask(old_models.Stage oldStage, String projectId, int nestingLevel) {
    final subtasks = <Task>[];

    // Конвертируем steps в подзадачи второго уровня
    for (final oldStep in oldStage.steps) {
      final stepTask = _convertStepToTask(oldStep, projectId, nestingLevel + 1);
      subtasks.add(stepTask);
    }

    return Task(
      id: oldStage.id,
      title: oldStage.title,
      description: oldStage.description,
      isCompleted: oldStage.isCompleted,
      completedSubtasks: _calculateCompletedSubtasks(subtasks),
      totalSubtasks: _calculateTotalSubtasks(subtasks),
      subtasks: subtasks,
      type: TaskType.multiStep,
      priority: oldStage.priority,
      dueDate: oldStage.dueDate,
      estimatedMinutes: oldStage.estimatedMinutes,
      projectId: projectId,
      nestingLevel: nestingLevel,
      createdAt: oldStage.createdAt,
      completedAt: oldStage.completedAt,
    );
  }

  // Конвертация Step в Task
  static Task _convertStepToTask(old_models.Step oldStep, String projectId, int nestingLevel) {
    return Task(
      id: oldStep.id,
      title: oldStep.title,
      description: oldStep.description,
      isCompleted: oldStep.isCompleted,
      completedSubtasks: 0,
      totalSubtasks: 0,
      subtasks: [], // Steps становятся задачами без подзадач
      type: TaskType.single,
      priority: oldStep.priority,
      dueDate: oldStep.dueDate,
      estimatedMinutes: oldStep.estimatedMinutes,
      projectId: projectId,
      nestingLevel: nestingLevel,
      createdAt: oldStep.createdAt,
      completedAt: oldStep.completedAt,
    );
  }

  // Конвертация типа задачи
  static TaskType _convertTaskType(old_models.TaskType oldType) {
    switch (oldType) {
      case old_models.TaskType.single:
        return TaskType.single;
      case old_models.TaskType.multiStep:
        return TaskType.multiStep;
      case old_models.TaskType.recurring:
        return TaskType.recurring;
      default:
        return TaskType.single;
    }
  }

  // Расчет выполненных подзадач
  static int _calculateCompletedSubtasks(List<Task> tasks) {
    return tasks.fold(0, (count, task) {
      return count + (task.isCompleted ? 1 : 0) + _calculateCompletedSubtasks(task.subtasks);
    });
  }

  // Расчет общего количества подзадач
  static int _calculateTotalSubtasks(List<Task> tasks) {
    return tasks.fold(0, (count, task) {
      return count + 1 + _calculateTotalSubtasks(task.subtasks);
    });
  }

  // Валидация мигрированных данных
  static bool validateMigration(Project migratedProject) {
    for (final task in migratedProject.tasks) {
      if (!_validateTask(task)) {
        return false;
      }
    }
    return true;
  }

  static bool _validateTask(Task task) {
    // Проверяем уровень вложенности
    if (task.nestingLevel > 2) {
      return false;
    }

    // Проверяем подзадачи
    for (final subtask in task.subtasks) {
      if (subtask.nestingLevel != task.nestingLevel + 1) {
        return false;
      }
      if (!_validateTask(subtask)) {
        return false;
      }
    }

    return true;
  }

  // Исправление мигрированных данных
  static Project fixMigratedProject(Project project) {
    final fixedTasks = project.tasks.map(_fixTask).toList();
    return project.copyWith(tasks: fixedTasks);
  }

  static Task _fixTask(Task task) {
    var fixedTask = task;

    // Исправляем уровень вложенности
    if (fixedTask.nestingLevel > 2) {
      fixedTask = fixedTask.copyWith(nestingLevel: 2);
    }

    // Исправляем подзадачи
    final fixedSubtasks = fixedTask.subtasks.map((subtask) {
      var fixedSubtask = _fixTask(subtask);
      if (fixedSubtask.nestingLevel != fixedTask.nestingLevel + 1) {
        fixedSubtask = fixedSubtask.copyWith(nestingLevel: fixedTask.nestingLevel + 1);
      }
      return fixedSubtask;
    }).toList();

    // Пересчитываем прогресс
    final completedSubtasks = _calculateCompletedSubtasks(fixedSubtasks);
    final totalSubtasks = _calculateTotalSubtasks(fixedSubtasks);

    return fixedTask.copyWith(
      subtasks: fixedSubtasks,
      completedSubtasks: completedSubtasks,
      totalSubtasks: totalSubtasks,
      isCompleted: completedSubtasks == totalSubtasks && totalSubtasks > 0,
    );
  }

  // Создание отчета о миграции
  static Map<String, dynamic> createMigrationReport(Project oldProject, Project newProject) {
    final oldTasksCount = oldProject.tasks.length;
    var oldStagesCount = 0;
    var oldStepsCount = 0;

    for (final task in oldProject.tasks) {
      oldStagesCount += task.stages.length;
      for (final stage in task.stages) {
        oldStepsCount += stage.steps.length;
      }
    }

    final newTasksCount = newProject.tasks.length;
    var newSubtasksCount = 0;

    for (final task in newProject.tasks) {
      newSubtasksCount += _countAllSubtasks(task);
    }

    return {
      'old_structure': {
        'tasks': oldTasksCount,
        'stages': oldStagesCount,
        'steps': oldStepsCount,
        'total_elements': oldTasksCount + oldStagesCount + oldStepsCount,
      },
      'new_structure': {
        'tasks': newTasksCount,
        'subtasks': newSubtasksCount,
        'total_elements': newTasksCount + newSubtasksCount,
      },
      'migration_successful': validateMigration(newProject),
    };
  }

  static int _countAllSubtasks(Task task) {
    return task.subtasks.fold(0, (count, subtask) {
      return count + 1 + _countAllSubtasks(subtask);
    });
  }
}