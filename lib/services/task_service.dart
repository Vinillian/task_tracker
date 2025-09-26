import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
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
    int colorValue = 0xFF2196F3,
    bool isTracked = true,
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
      plannedDate: null,
      colorValue: colorValue,
      isTracked: isTracked,
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
      plannedDate: null,
      recurrence: null,
    );
  }

  // Создание шага
  static custom_step.Step createStep(String name, int steps, {String stepType = 'stepByStep'}) {
    return custom_step.Step(
      name: name,
      totalSteps: steps,
      completedSteps: 0,
      stepType: stepType,
      isCompleted: false,
      plannedDate: null,
      recurrence: null,
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
      plannedDate: task.plannedDate,
      colorValue: task.colorValue,
      isTracked: task.isTracked,
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
      plannedDate: stage.plannedDate,
      recurrence: stage.recurrence,
    );
  }

  // Переключение завершения шага
  static custom_step.Step toggleStepCompletion(custom_step.Step step) {
    return custom_step.Step(
      name: step.name,
      completedSteps: step.completedSteps,
      totalSteps: step.totalSteps,
      stepType: step.stepType,
      isCompleted: !step.isCompleted,
      plannedDate: step.plannedDate,
      recurrence: step.recurrence,
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
      plannedDate: task.plannedDate,
      colorValue: task.colorValue,
      isTracked: task.isTracked,
    );
  }

  // Добавление прогресса к этапу
  static Stage addProgressToStage(Stage stage, int steps) {
    if (stage.stageType == 'singleStep') {
      return toggleStageCompletion(stage);
    }

    final newCompletedSteps = (stage.completedSteps + steps).clamp(0, stage.totalSteps);
    final isCompleted = newCompletedSteps >= stage.totalSteps;

    return Stage(
      name: stage.name,
      completedSteps: newCompletedSteps,
      totalSteps: stage.totalSteps,
      stageType: stage.stageType,
      isCompleted: isCompleted,
      steps: stage.steps,
      plannedDate: stage.plannedDate,
      recurrence: stage.recurrence,
    );
  }

  // Добавление прогресса к шагу
  static custom_step.Step addProgressToStep(custom_step.Step step, int steps) {
    if (step.stepType == 'singleStep') {
      return toggleStepCompletion(step);
    }

    final newCompletedSteps = (step.completedSteps + steps).clamp(0, step.totalSteps);
    final isCompleted = newCompletedSteps >= step.totalSteps;

    return custom_step.Step(
      name: step.name,
      completedSteps: newCompletedSteps,
      totalSteps: step.totalSteps,
      stepType: step.stepType,
      isCompleted: isCompleted,
      plannedDate: step.plannedDate,
      recurrence: step.recurrence,
    );
  }

  // Обновление задачи
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
      plannedDate: oldTask.plannedDate,
      colorValue: colorValue ?? oldTask.colorValue,
      isTracked: oldTask.isTracked,
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
      plannedDate: oldStage.plannedDate,
      recurrence: oldStage.recurrence,
    );
  }

  // Обновление шага
  static custom_step.Step updateStep(custom_step.Step oldStep, String name, int steps) {
    return custom_step.Step(
      name: name,
      completedSteps: oldStep.completedSteps.clamp(0, steps),
      totalSteps: steps,
      stepType: oldStep.stepType,
      isCompleted: oldStep.isCompleted,
      plannedDate: oldStep.plannedDate,
      recurrence: oldStep.recurrence,
    );
  }
}