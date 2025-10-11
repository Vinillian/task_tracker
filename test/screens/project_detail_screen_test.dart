import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker/screens/project_detail_screen.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/services/task_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProject = Project(
    id: 'test_1',
    name: 'Test Project',
    description: 'Test Description',
    createdAt: DateTime.now(),
  );

  testWidgets('ProjectDetailScreen builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ProjectDetailScreen(
            project: testProject,
            projectIndex: 0,
            onProjectUpdated: (project) {},
            taskService: TaskService(),
          ),
        ),
      ),
    );

    expect(find.byType(ProjectDetailScreen), findsOneWidget);
    // Используем findsAtLeast вместо findsOne т.к. текст может дублироваться
    expect(find.text('Test Project'), findsAtLeast(1));
  });

  testWidgets('ProjectDetailScreen has app bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ProjectDetailScreen(
            project: testProject,
            projectIndex: 0,
            onProjectUpdated: (project) {},
            taskService: TaskService(),
          ),
        ),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
  });
}