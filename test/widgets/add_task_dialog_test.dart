import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/widgets/add_task_dialog.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AddTaskDialog builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            onTaskCreated: (title, description, type, steps, parentId) {},
            projectId: 'test_project',
            parentId: null,
          ),
        ),
      ),
    );

    expect(find.byType(AddTaskDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('AddTaskDialog has required input fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            onTaskCreated: (title, description, type, steps, parentId) {},
            projectId: 'test_project',
            parentId: null,
          ),
        ),
      ),
    );

    // Проверяем наличие полей ввода
    expect(find.byType(TextField), findsAtLeast(2));
    expect(find.text('Название задачи*'), findsAtLeast(1));
    expect(find.text('Описание задачи'), findsAtLeast(1));
  });

  testWidgets('AddTaskDialog has task type dropdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTaskDialog(
            onTaskCreated: (title, description, type, steps, parentId) {},
            projectId: 'test_project',
            parentId: null,
          ),
        ),
      ),
    );

    expect(find.byType(DropdownButton<TaskType>), findsOneWidget);
  });
}