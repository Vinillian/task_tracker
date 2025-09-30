// test/widgets/task_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart';
import 'package:task_tracker/widgets/task_card.dart';

void main() {
  group('TaskCard Widget Tests', () {
    testWidgets('TaskCard displays task information correctly', (WidgetTester tester) async {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              taskIndex: 0,
              onToggle: () {},
              onEdit: () {},
              onDelete: () {},
              onUpdateSteps: (_) {},
            ),
          ),
        ),
      );

      // Проверяем что заголовок и описание отображаются
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);

      // Проверяем что чекбокс отображается для одиночной задачи
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('TaskCard shows progress indicator for step-by-step task', (WidgetTester tester) async {
      final task = Task(
        id: '1',
        title: 'Step Task',
        description: 'Step Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              taskIndex: 0,
              onToggle: () {},
              onEdit: () {},
              onDelete: () {},
              onUpdateSteps: (_) {},
            ),
          ),
        ),
      );

      // Проверяем что отображается прогресс бар вместо чекбокса
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('TaskCard shows subTasks indicator', (WidgetTester tester) async {
      final subTask = Task(id: '1-1', title: 'Sub Task', description: '');
      final task = Task(
        id: '1',
        title: 'Parent Task',
        description: 'Parent Description',
        subTasks: [subTask],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              taskIndex: 0,
              onToggle: () {},
              onEdit: () {},
              onDelete: () {},
              onUpdateSteps: (_) {},
            ),
          ),
        ),
      );

      // Проверяем что отображается индикатор подзадач
      expect(find.text('1'), findsOneWidget); // Количество подзадач
    });

    // В test/widgets/task_card_test.dart ИСПРАВИТЬ последний тест:
    testWidgets('TaskCard calls callbacks when buttons pressed', (WidgetTester tester) async {
      bool editCalled = false;
      bool deleteCalled = false;

      final task = Task(
          id: '1',
          title: 'Test Task',
          description: 'Test Description'
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              taskIndex: 0,
              onToggle: () {}, // Просто пустая функция
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
              onUpdateSteps: (_) {},
            ),
          ),
        ),
      );

      // Нажимаем кнопку редактирования
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(editCalled, true);

      // Нажимаем кнопку удаления
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(deleteCalled, true);
    });
  });
}