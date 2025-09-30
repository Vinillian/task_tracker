// test/smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/task.dart';
import '../lib/models/project.dart';

void main() {
  test('Smoke test - basic model creation', () {
    // Просто проверяем, что можем создать объекты без ошибок
    final task = Task(
      name: 'Smoke Test Task',
      completedSteps: 0,
      totalSteps: 1,
      taskType: 'singleStep',
      isCompleted: false,
    );

    final project = Project(name: 'Smoke Test Project', tasks: [task]);

    expect(task.name, 'Smoke Test Task');
    expect(project.name, 'Smoke Test Project');
    expect(project.tasks.length, 1);
  });
}