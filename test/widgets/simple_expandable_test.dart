import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/widgets/expandable_task_card.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart'; // ✅ ДОБАВИТЬ ЭТОТ ИМПОРТ

void main() {
  group('Simple ExpandableTaskCard Tests', () {
    testWidgets('Basic task card renders correctly', (WidgetTester tester) async {
      final simpleTask = Task(
        id: '1',
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

    testWidgets('Task with subtasks shows expand button', (WidgetTester tester) async {
      final taskWithSubtasks = Task(
        id: '1',
        title: 'Parent Task',
        description: 'Has subtasks',
        subTasks: [
          Task(id: '1-1', title: 'Child Task', description: ''),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: taskWithSubtasks,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show expand/collapse button when there are subtasks
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('Step task shows progress indicator', (WidgetTester tester) async {
      final stepTask = Task(
        id: '1',
        title: 'Step Task',
        description: 'Step Description',
        type: TaskType.stepByStep, // ✅ Теперь TaskType определен
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
  });
}