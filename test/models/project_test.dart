import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/project.dart';

void main() {
  group('Project Model Tests - Flat Structure', () {
    test('Project creation without tasks', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.id, '1');
      expect(project.name, 'Test Project');
      expect(project.description, 'Test Description');
      expect(project.createdAt, DateTime(2024, 1, 1));
    });

    test('Project JSON serialization without tasks', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = project.toJson();
      final deserialized = Project.fromJson(json);

      expect(deserialized.id, project.id);
      expect(deserialized.name, project.name);
      expect(deserialized.description, project.description);
    });

    test('Project copyWith method', () {
      final original = Project(
        id: '1',
        name: 'Original',
        description: 'Desc',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated',
        description: 'New Desc',
      );

      expect(updated.id, '1');
      expect(updated.name, 'Updated');
      expect(updated.description, 'New Desc');
      expect(updated.createdAt, DateTime(2024, 1, 1));
    });
  });
}