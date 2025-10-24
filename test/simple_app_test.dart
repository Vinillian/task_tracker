import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker/main.dart';
import 'package:task_tracker/providers/project_provider.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHiveStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockHiveStorageService();
    setupStorageServiceMocks(mockStorageService);
  });

  testWidgets('MyApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
        child: const MyApp(),
      ),
    );

    // Ждем завершения асинхронной инициализации
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MyApp has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Task Tracker');
  });
}
