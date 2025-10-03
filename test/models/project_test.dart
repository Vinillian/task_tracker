// test/models/project_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart'; // ✅ ДОБАВИТЬ ЭТОТ ИМПОРТ

void main() {
  group('Project Model Tests', () {
    test('Project creation and basic properties', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.id, '1');
      expect(project.name, 'Test Project');
      expect(project.description, 'Test Description');
      expect(project.tasks, isEmpty);
      expect(project.createdAt, DateTime(2024, 1, 1));
    });

    test('Project progress calculation with no tasks', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [],
        createdAt: DateTime.now(),
      );

      expect(project.progress, 0.0);
    });

    test('Project progress calculation with tasks', () {
      final task1 = Task(id: '1', title: 'Task 1', description: '', isCompleted: true);
      final task2 = Task(id: '2', title: 'Task 2', description: '', isCompleted: false);

      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [task1, task2],
        createdAt: DateTime.now(),
      );

      expect(project.progress, 0.5); // (1.0 + 0.0) / 2 = 0.5
    });

    test('Project task counters', () {
      final completedTask = Task(id: '1', title: 'Completed', description: '', isCompleted: true);
      final pendingTask = Task(id: '2', title: 'Pending', description: '', isCompleted: false);

      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [completedTask, pendingTask],
        createdAt: DateTime.now(),
      );

      expect(project.totalTasks, 2);
      expect(project.completedTasks, 1);
    });

    test('Project copyWith method', () {
      final original = Project(
        id: '1',
        name: 'Original',
        description: 'Desc',
        tasks: [],
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated',
        description: 'New Desc',
      );

      expect(updated.id, '1');
      expect(updated.name, 'Updated');
      expect(updated.description, 'New Desc');
      expect(updated.tasks, isEmpty);
      expect(updated.createdAt, DateTime(2024, 1, 1));
    });

    test('Project JSON serialization', () {
      final task = Task(id: '1', title: 'Test Task', description: '');
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [task],
        createdAt: DateTime(2024, 1, 1),
      );

      final json = project.toJson();
      final deserialized = Project.fromJson(json);

      expect(deserialized.id, project.id);
      expect(deserialized.name, project.name);
      expect(deserialized.description, project.description);
      expect(deserialized.tasks.length, 1);
      expect(deserialized.tasks[0].title, 'Test Task');
    });
  });


  test('Project progress includes all nested tasks', () {
    // Глубоко вложенные задачи
    final subSubTask = Task(id: '1-1-1', title: 'Sub Sub Task', description: '', isCompleted: true);
    final subTask = Task(id: '1-1', title: 'Sub Task', description: '', isCompleted: false, subTasks: [subSubTask]);
    final mainTask = Task(id: '1', title: 'Main Task', description: '', isCompleted: false, subTasks: [subTask]);

    final project = Project(
      id: '1',
      name: 'Test Project',
      description: 'Test Description',
      tasks: [mainTask],
      createdAt: DateTime.now(),
    );

    // Прогресс должен учитывать ВСЕ задачи:
    // mainTask: 0% (не выполнена)
    // subTask: 0% (не выполнена)
    // subSubTask: 100% (выполнена)
    // Общий прогресс: (0.0 + 0.0 + 1.0) / 3 = 0.333...
    expect(project.progress, closeTo(0.333, 0.001));
    expect(project.totalTasks, 3); // Все 3 задачи
    expect(project.completedTasks, 1); // Только subSubTask выполнена
  });

  test('Task progress shows only task itself (ignores subtasks)', () {
    final subTask = Task(id: '1-1', title: 'Sub Task', description: '', isCompleted: true);
    final task = Task(
        id: '1',
        title: 'Main Task',
        description: '',
        isCompleted: false, // Основная задача не выполнена
        subTasks: [subTask] // Но подзадача выполнена
    );

    // ✅ Прогресс показывает ТОЛЬКО собственную задачу (0%)
    // Подзадачи не влияют на прогресс основной задачи
    expect(task.progress, 0.0);

    // ✅ Подзадача имеет свой собственный прогресс (100%)
    expect(subTask.progress, 1.0);
  });

  test('Project progress with complex nesting', () {
    // Создаем сложную структуру:
    // - Main Task 1: 0% (не выполнена)
    //   - Sub Task 1: 100% (выполнена)
    //   - Sub Task 2: 0% (не выполнена)
    //     - Sub Sub Task: 100% (выполнена)
    // - Main Task 2: 100% (выполнена)

    final subSubTask = Task(id: '1-2-1', title: 'Sub Sub Task', description: '', isCompleted: true);
    final subTask1 = Task(id: '1-1', title: 'Sub Task 1', description: '', isCompleted: true);
    final subTask2 = Task(id: '1-2', title: 'Sub Task 2', description: '', isCompleted: false, subTasks: [subSubTask]);
    final mainTask1 = Task(id: '1', title: 'Main Task 1', description: '', isCompleted: false, subTasks: [subTask1, subTask2]);
    final mainTask2 = Task(id: '2', title: 'Main Task 2', description: '', isCompleted: true);

    final project = Project(
      id: '1',
      name: 'Test Project',
      description: 'Test Description',
      tasks: [mainTask1, mainTask2],
      createdAt: DateTime.now(),
    );

    // Всего задач: 5 (mainTask1, subTask1, subTask2, subSubTask, mainTask2)
    // Выполнено: 3 (subTask1, subSubTask, mainTask2)
    // Прогресс: (0 + 1 + 0 + 1 + 1) / 5 = 3/5 = 0.6
    expect(project.progress, 0.6);
    expect(project.totalTasks, 5);
    expect(project.completedTasks, 3);
  });

  // Добавить в существующий файл:
  test('Project progress calculation with step-by-step tasks', () {
    final stepTask = Task(
      id: '1',
      title: 'Step Task',
      description: '',
      type: TaskType.stepByStep,
      totalSteps: 5,
      completedSteps: 3, // 60% progress
    );

    final singleTask = Task(
      id: '2',
      title: 'Single Task',
      description: '',
      type: TaskType.single,
      isCompleted: true, // 100% progress
    );

    final project = Project(
      id: '1',
      name: 'Test Project',
      description: 'Test Description',
      tasks: [stepTask, singleTask],
      createdAt: DateTime.now(),
    );

    // Progress should be average of both tasks: (0.6 + 1.0) / 2 = 0.8
    expect(project.progress, 0.8);
  });

  test('Task own progress calculation for step-by-step', () {
    final stepTask = Task(
      id: '1',
      title: 'Step Task',
      description: '',
      type: TaskType.stepByStep,
      totalSteps: 5,
      completedSteps: 3,
    );

    expect(stepTask.progress, 0.6); // 3/5 = 60%
  });
}