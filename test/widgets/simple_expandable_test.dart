import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/widgets/expandable_task_card.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart';
import 'package:task_tracker/services/task_service.dart';

void main() {
  group('Simple ExpandableTaskCard Tests - Updated for Flat Structure', () {
    late TaskService taskService;

    setUp(() {
      taskService = TaskService();
    });

    testWidgets('Basic task card renders correctly', (WidgetTester tester) async {
      final simpleTask = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Simple Task',
        description: 'Simple Description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: simpleTask,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              taskService: taskService,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Basic checks that should always pass
      expect(find.text('Simple Task'), findsOneWidget);
      expect(find.text('Simple Description'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Step task shows progress indicator', (WidgetTester tester) async {
      final stepTask = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Step Task',
        description: 'Step Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: stepTask,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              taskService: taskService,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show progress for step tasks
      expect(find.text('2/5'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Completed task shows checkmark', (WidgetTester tester) async {
      final completedTask = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Completed Task',
        description: 'Completed Description',
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: completedTask,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              taskService: taskService,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show checked checkbox for completed tasks
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('Task with description shows description text', (WidgetTester tester) async {
      final taskWithDescription = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Task with Description',
        description: 'This is a detailed description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: taskWithDescription,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              taskService: taskService,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('This is a detailed description'), findsOneWidget);
    });
  });
}