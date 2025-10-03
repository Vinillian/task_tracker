import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/widgets/add_task_dialog.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('AddTaskDialog Tests', () {
    late Function(String, String, TaskType, int) onTaskCreated;

    setUp(() {
      onTaskCreated = (title, description, type, steps) {};
    });

    testWidgets('Dialog shows correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(onTaskCreated: onTaskCreated),
          ),
        ),
      );

      expect(find.text('Добавить задачу'), findsOneWidget);
      expect(find.text('Название задачи*'), findsOneWidget);
      expect(find.text('Одиночная'), findsOneWidget);
    });

    testWidgets('Step input field appears for step-by-step tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(onTaskCreated: onTaskCreated),
          ),
        ),
      );

      // Initially step field should not be visible
      expect(find.text('Количество шагов:'), findsNothing);

      // Change to step-by-step type
      await tester.tap(find.text('Одиночная'));
      await tester.pump();
      await tester.tap(find.text('Пошаговая'));
      await tester.pump();

      // Step field should now be visible
      expect(find.text('Количество шагов:'), findsOneWidget);
    });

    testWidgets('Basic functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(onTaskCreated: onTaskCreated),
          ),
        ),
      );

      // Test that we can enter text
      await tester.enterText(find.byType(TextField).first, 'Test Task');
      expect(find.text('Test Task'), findsOneWidget);
    });
  });
}