// test/simple_app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp builds without crashing', (WidgetTester tester) async {
    // Просто проверяем что приложение строится без ошибок
    await tester.pumpWidget(const MyApp());

    // Проверяем что MaterialApp создан
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('MyApp has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Проверяем что заголовок установлен
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Task Tracker');
  });
}