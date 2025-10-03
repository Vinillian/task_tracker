import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/widgets/expandable_task_card.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('ExpandableTaskCard Step Management Tests', () {
    late Task stepTask;
    late Function(Task) onTaskUpdated;
    late Function() onTaskDeleted;

    setUp(() {
      stepTask = Task(
        id: '1',
        title: 'Test Step Task',
        description: 'Test Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 2,
      );

      onTaskUpdated = (task) {};
      onTaskDeleted = () {};
    });

    testWidgets('ExpandableTaskCard builds without error for step task', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: stepTask,
              taskIndex: 0,
              onTaskUpdated: onTaskUpdated,
              onTaskDeleted: onTaskDeleted,
              level: 0,
            ),
          ),
        ),
      );

      // Просто проверяем что виджет строится без ошибок
      expect(find.text('Test Step Task'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget); // Прогресс шагов
    });

    testWidgets('Step management button shows for step-by-step tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: stepTask,
              taskIndex: 0,
              onTaskUpdated: onTaskUpdated,
              onTaskDeleted: onTaskDeleted,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // ✅ ДОБАВИТЬ ДЛЯ ПОЛНОЙ ОТРИСОВКИ

      // ✅ ИСПРАВЛЕНО: используем правильную иконку play_circle_outline
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('Step management dialog shows correct controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: stepTask,
              taskIndex: 0,
              onTaskUpdated: onTaskUpdated,
              onTaskDeleted: onTaskDeleted,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open step management dialog
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('Управление прогрессом: Test Step Task'), findsOneWidget);
      expect(find.text('Прогресс: 2/5'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Сброс'), findsOneWidget);

      // ✅ ИСПРАВЛЕНО: ищем иконки ВНУТРИ диалога
      expect(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.remove),
      ), findsOneWidget); // Кнопка минус в диалоге
      expect(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.add),
      ), findsOneWidget); // Кнопка плюс в диалоге
    });

    testWidgets('Step buttons work correctly in dialog', (WidgetTester tester) async {
      bool updateCalled = false;
      Task? updatedTask;

      onTaskUpdated = (task) {
        updateCalled = true;
        updatedTask = task;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableTaskCard(
              task: stepTask,
              taskIndex: 0,
              onTaskUpdated: onTaskUpdated,
              onTaskDeleted: onTaskDeleted,
              level: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog and test +1 button
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle();

      // ✅ ИСПРАВЛЕНО: нажимаем на иконку плюса В ДИАЛОГЕ
      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.add),
      ));
      await tester.pump();
      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      expect(updateCalled, true);
      expect(updatedTask?.completedSteps, 3);
    });
  });
}