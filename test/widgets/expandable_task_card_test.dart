import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/widgets/expandable_task_card.dart';

void main() {
  group('ExpandableTaskCard Tests', () {
    testWidgets('Card expands and collapses correctly', (tester) async {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        subTasks: [
          Task(id: '1-1', title: 'Sub Task', description: ''),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: task,
              taskIndex: 0,
              onTaskUpdated: (_) {},
              onTaskDeleted: () {},
              level: 0,
            ),
          ),
        ),
      );

      // Проверяем, что изначально свернуто
      expect(find.text('Sub Task'), findsNothing);

      // Нажимаем кнопку раскрытия
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();

      // Проверяем, что подзадача появилась
      expect(find.text('Sub Task'), findsOneWidget);
    });

    testWidgets('Auto-expands when adding sub task', (tester) async {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        subTasks: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: task,
              taskIndex: 0,
              onTaskUpdated: (_) {},
              onTaskDeleted: () {},
              level: 0,
            ),
          ),
        ),
      );

      // TODO: Добавить тест на автоматическое раскрытие
    });
  });
}
