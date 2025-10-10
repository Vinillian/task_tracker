import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/widgets/add_task_dialog.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('AddTaskDialog Tests', () {
    late Function(String, String, TaskType, int, String?) onTaskCreated;

    setUp(() {
      onTaskCreated = (title, description, type, steps, parentId) {};
    });

    testWidgets('Dialog contains required elements for root task', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(
              onTaskCreated: onTaskCreated,
              projectId: 'test_project',
              parentId: null,
            ),
          ),
        ),
      );

      // Проверяем наличие основных элементов без поиска дублирующего текста
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Название задачи*'), findsOneWidget);
      expect(find.text('Описание задачи'), findsOneWidget);
      expect(find.text('Одиночная'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
    });

    testWidgets('Step input field appears for step-by-step tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(
              onTaskCreated: onTaskCreated,
              projectId: 'test_project',
              parentId: null,
            ),
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

    testWidgets('Can enter task title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(
              onTaskCreated: onTaskCreated,
              projectId: 'test_project',
              parentId: null,
            ),
          ),
        ),
      );

      // Test that we can enter text in both fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'Test Task Title');
      await tester.enterText(textFields.at(1), 'Test Task Description');

      expect(find.text('Test Task Title'), findsOneWidget);
      expect(find.text('Test Task Description'), findsOneWidget);
    });

    testWidgets('Task type dropdown works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(
              onTaskCreated: onTaskCreated,
              projectId: 'test_project',
              parentId: null,
            ),
          ),
        ),
      );

      // Initially single task type is selected
      expect(find.text('Одиночная'), findsOneWidget);

      // Change to step-by-step
      await tester.tap(find.text('Одиночная'));
      await tester.pump();
      await tester.tap(find.text('Пошаговая'));
      await tester.pump();

      // Now step-by-step should be selected
      expect(find.text('Пошаговая'), findsOneWidget);
    });

    testWidgets('Step controls work for step-by-step tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddTaskDialog(
              onTaskCreated: onTaskCreated,
              projectId: 'test_project',
              parentId: null,
            ),
          ),
        ),
      );

      // Switch to step-by-step type
      await tester.tap(find.text('Одиночная'));
      await tester.pump();
      await tester.tap(find.text('Пошаговая'));
      await tester.pump();

      // Find step control buttons
      final incrementButton = find.byIcon(Icons.add);
      final decrementButton = find.byIcon(Icons.remove);

      expect(incrementButton, findsOneWidget);
      expect(decrementButton, findsOneWidget);

      // Test increment
      await tester.tap(incrementButton);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      // Test decrement
      await tester.tap(decrementButton);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });
  });
}