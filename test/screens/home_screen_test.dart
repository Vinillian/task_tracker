import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker/screens/home_screen.dart';
import 'package:task_tracker/providers/project_provider.dart';
import 'package:task_tracker/providers/task_provider.dart';
import '../test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHiveStorageService mockStorageService;
  late MockTaskService mockTaskService;

  setUp(() {
    mockStorageService = MockHiveStorageService();
    mockTaskService = MockTaskService();

    setupStorageServiceMocks(mockStorageService);
    setupTaskServiceMocks(mockTaskService);
  });

  testWidgets('HomeScreen builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          taskServiceProvider.overrideWithValue(mockTaskService),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Ждем завершения инициализации
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('HomeScreen shows empty state when no projects',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          taskServiceProvider.overrideWithValue(mockTaskService),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Нет проектов'), findsOneWidget);
    expect(find.text('Нажмите + чтобы создать первый проект'), findsOneWidget);
  });

  testWidgets('HomeScreen has app bar with title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          taskServiceProvider.overrideWithValue(mockTaskService),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Task Tracker 💾 (Riverpod)'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
