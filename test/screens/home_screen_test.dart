import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_tracker/screens/home_screen.dart';
import 'package:task_tracker/providers/project_provider.dart';
import 'package:task_tracker/providers/task_provider.dart';
import 'package:task_tracker/models/project.dart';

// Моки для провайдеров
class MockProjectNotifier extends Mock implements ProjectNotifier {}
class MockTaskNotifier extends Mock implements TaskNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProjectNotifier mockProjectNotifier;
  late MockTaskNotifier mockTaskNotifier;

  setUp(() {
    mockProjectNotifier = MockProjectNotifier();
    mockTaskNotifier = MockTaskNotifier();
  });

  testWidgets('HomeScreen shows empty state when no projects', (WidgetTester tester) async {
    // Настраиваем моки - пустой список проектов
    when(() => mockProjectNotifier.state).thenReturn([]);
    when(() => mockProjectNotifier.loadProjects()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) => mockProjectNotifier),
          tasksProvider.overrideWith((ref) => mockTaskNotifier),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Сначала видим индикатор загрузки
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Ждем немного вместо pumpAndSettle
    await tester.pump(const Duration(milliseconds: 100));

    // Теперь видим пустое состояние
    expect(find.text('Нет проектов'), findsOneWidget);
    expect(find.text('Нажмите + чтобы создать первый проект'), findsOneWidget);
  });

  testWidgets('HomeScreen shows create project button', (WidgetTester tester) async {
    // Настраиваем моки - пустой список проектов
    when(() => mockProjectNotifier.state).thenReturn([]);
    when(() => mockProjectNotifier.loadProjects()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) => mockProjectNotifier),
          tasksProvider.overrideWith((ref) => mockTaskNotifier),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Должна быть кнопка добавления
    expect(find.byIcon(Icons.add), findsAtLeast(1));
  });

  testWidgets('HomeScreen shows projects when they exist', (WidgetTester tester) async {
    // Настраиваем моки - есть проекты
    final projects = [
      Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        createdAt: DateTime.now(),
      ),
    ];

    when(() => mockProjectNotifier.state).thenReturn(projects);
    when(() => mockProjectNotifier.loadProjects()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) => mockProjectNotifier),
          tasksProvider.overrideWith((ref) => mockTaskNotifier),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Должен показывать проект
    expect(find.text('Test Project'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
  });
}