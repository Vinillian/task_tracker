import '../models/task.dart';
import '../models/stage.dart'; // ← НОВЫЙ импорт
import '../models/step.dart';  // ← НОВЫЙ импорт
import '../models/task_type.dart';
import '../models/recurrence.dart';

class TaskService {
  // Создание задачи
  static Task createTask({
    required String name,
    required int steps,
    TaskType taskType = TaskType.stepByStep,
    Recurrence? recurrence,
    DateTime? dueDate,
    String? description,
    int colorValue = 0xFF2196F3, // Цвет по умолчанию
  }) {
    return Task(
      name: name,
      totalSteps: steps,
      completedSteps: 0,
      stages: [],
      taskType: taskType.toString(),
      recurrence: recurrence,
      dueDate: dueDate,
      description: description,
      isCompleted: false,
    );
  }

  // Создание этапа
  static Stage createStage(String name, int steps, {String stageType = 'stepByStep'}) {
    return Stage(
      name: name,
      totalSteps: steps,
      completedSteps: 0,
      stageType: stageType,
      isCompleted: false,
      steps: [],
    );
  }

  // Создание шага
  static Step createStep(String name, int steps, {String stepType = 'stepByStep'}) {
    return Step(
      name: name,
      totalSteps: steps,
      completedSteps: 0,
      stepType: stepType,
      isCompleted: false,
    );
  }

  // Переключение завершения задачи
  static Task toggleTaskCompletion(Task task) {
    return Task(
      name: task.name,
      completedSteps: task.completedSteps,
      totalSteps: task.totalSteps,
      stages: task.stages,
      taskType: task.taskType,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      isCompleted: !task.isCompleted,
      description: task.description,
    );
  }

  // Переключение завершения этапа
  static Stage toggleStageCompletion(Stage stage) {
    return Stage(
      name: stage.name,
      completedSteps: stage.completedSteps,
      totalSteps: stage.totalSteps,
      stageType: stage.stageType,
      isCompleted: !stage.isCompleted,
      steps: stage.steps,
    );
  }

  // Переключение завершения шага
  static Step toggleStepCompletion(Step step) {
    return Step(
      name: step.name,
      completedSteps: step.completedSteps,
      totalSteps: step.totalSteps,
      stepType: step.stepType,
      isCompleted: !step.isCompleted,
    );
  }

  // Добавление прогресса к задаче
  static Task addProgressToTask(Task task, int steps) {
    final newCompletedSteps = (task.completedSteps + steps).clamp(0, task.totalSteps);
    final isCompleted = newCompletedSteps >= task.totalSteps;

    return Task(
      name: task.name,
      completedSteps: newCompletedSteps,
      totalSteps: task.totalSteps,
      stages: task.stages,
      taskType: task.taskType,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      isCompleted: isCompleted,
      description: task.description,
    );
  }

  // Добавление прогресса к этапу
  static Stage addProgressToStage(Stage stage, int steps) {
    if (stage.stageType == 'singleStep') {
      return toggleStageCompletion(stage);
    }

    return Stage(
      name: stage.name,
      completedSteps: (stage.completedSteps + steps).clamp(0, stage.totalSteps),
      totalSteps: stage.totalSteps,
      stageType: stage.stageType,
      isCompleted: stage.isCompleted,
      steps: stage.steps,
    );
  }

  // Добавление прогресса к шагу
  static Step addProgressToStep(Step step, int steps) {
    if (step.stepType == 'singleStep') {
      return toggleStepCompletion(step);
    }

    return Step(
      name: step.name,
      completedSteps: (step.completedSteps + steps).clamp(0, step.totalSteps),
      totalSteps: step.totalSteps,
      stepType: step.stepType,
      isCompleted: step.isCompleted,
    );
  }

  // Обновление задачи с сохранением цвета
  static Task updateTask(Task oldTask, String name, int steps, {int? colorValue}) {
    return Task(
      name: name,
      completedSteps: oldTask.completedSteps.clamp(0, steps),
      totalSteps: steps,
      stages: oldTask.stages,
      taskType: oldTask.taskType,
      recurrence: oldTask.recurrence,
      dueDate: oldTask.dueDate,
      isCompleted: oldTask.isCompleted,
      description: oldTask.description,
      colorValue: colorValue ?? oldTask.colorValue, // Сохраняем цвет
    );
  }

  // Обновление этапа
  static Stage updateStage(Stage oldStage, String name, int steps) {
    return Stage(
      name: name,
      completedSteps: oldStage.completedSteps.clamp(0, steps),
      totalSteps: steps,
      stageType: oldStage.stageType,
      isCompleted: oldStage.isCompleted,
      steps: oldStage.steps,
    );
  }

  // Обновление шага
  static Step updateStep(Step oldStep, String name, int steps) {
    return Step(
      name: name,
      completedSteps: oldStep.completedSteps.clamp(0, steps),
      totalSteps: steps,
      stepType: oldStep.stepType,
      isCompleted: oldStep.isCompleted,
    );
  }
}