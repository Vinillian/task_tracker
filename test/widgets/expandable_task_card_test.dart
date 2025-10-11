import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker/widgets/expandable_task_card.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTask = Task(
    id: 'test_1',
    projectId: 'project_1',
    title: 'Test Task',
    description: 'Test Description',
  );

  testWidgets('ExpandableTaskCard builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: testTask,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              taskService: TaskService(),
              level: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ExpandableTaskCard), findsOneWidget);
    expect(find.text('Test Task'), findsAtLeast(1));
  });

  testWidgets('ExpandableTaskCard shows task description', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: testTask,
              taskIndex: 0,
              onTaskUpdated: (task) {},
              onTaskDeleted: () {},
              taskService: TaskService(),
              level: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test Description'), findsAtLeast(1));
  });
}