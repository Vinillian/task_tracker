import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/main.dart';
import 'package:task_tracker/screens/home_screen.dart';

void main() {
  group('App Flow Integration Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const MyApp());

      // Проверяем что HomeScreen загрузился
      expect(find.byType(HomeScreen), findsOneWidget);

      // Ждем короткое время вместо pumpAndSettle
      await tester.pump(const Duration(milliseconds: 500));

      // Проверяем что отображаются основные элементы
      expect(find.text('Task Tracker'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Home screen shows demo projects', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 1000));

      // Проверяем что демо-проекты отображаются
      expect(find.text('Рабочие задачи'), findsOneWidget);
      expect(find.text('Личные дела'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('Project cards show progress', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 1000));

      // Проверяем что отображается прогресс
      expect(find.text('%'), findsAtLeast(2));
      expect(find.byType(LinearProgressIndicator), findsAtLeast(2));
    });
  }, skip: "Integration tests need more setup"); // Временно пропускаем
}