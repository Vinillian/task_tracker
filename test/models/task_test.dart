// test/models/task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('Task creation with default values', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
      );

      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.isCompleted, false);
    });

    test('Task copyWith method', () {
      final original = Task(
        id: '1',
        title: 'Original',
        description: 'Desc',
        isCompleted: false,
      );

      final updated = original.copyWith(
        title: 'Updated',
        isCompleted: true,
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated');
      expect(updated.description, 'Desc');
      expect(updated.isCompleted, true);
    });

    test('Task JSON serialization', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: false,
      );

      final json = task.toJson();
      final deserialized = Task.fromJson(json);

      expect(deserialized.id, task.id);
      expect(deserialized.title, task.title);
      expect(deserialized.description, task.description);
      expect(deserialized.isCompleted, task.isCompleted);
    });
  });
}