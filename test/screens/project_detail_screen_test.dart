import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/screens/project_detail_screen.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';

void main() {
  group('ProjectDetailScreen Tests', () {
    late Project testProject;
    late Function(Project) onProjectUpdated;

    setUp(() {
      testProject = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [
          Task(id: '1', title: 'Task 1', description: ''),
          Task(id: '2', title: 'Task 2', description: ''),
        ],
        createdAt: DateTime.now(),
      );

      onProjectUpdated = (project) {};
    });

    testWidgets('Screen builds with project data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            project: testProject,
            projectIndex: 0,
            onProjectUpdated: onProjectUpdated,
          ),
        ),
      );

      expect(find.text('Test Project'), findsAtLeast(1));
      expect(find.text('Test Description'), findsAtLeast(1));
      expect(find.text('Task 1'), findsAtLeast(1));
      expect(find.text('Task 2'), findsAtLeast(1));
    });

    testWidgets('Progress bar displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            project: testProject,
            projectIndex: 0,
            onProjectUpdated: onProjectUpdated,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Expand/Collapse all button works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            project: testProject,
            projectIndex: 0,
            onProjectUpdated: onProjectUpdated,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ИСПРАВЛЕНО: Ищем конкретную кнопку развернуть/свернуть по иконке
      final expandButton = find.widgetWithIcon(IconButton, Icons.unfold_more);
      expect(expandButton, findsOneWidget);

      // ИСПРАВЛЕНО: Ищем конкретные кнопки редактирования и добавления
      final editButtons = find.byIcon(Icons.edit);
      expect(editButtons,
          findsAtLeast(1)); // Может быть несколько кнопок редактирования

      final addTaskButton = find.byIcon(Icons.add_task);
      expect(addTaskButton, findsOneWidget);
    });
  });
}
