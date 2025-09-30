// test/widgets/simple_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Basic widget test - Checkbox', (WidgetTester tester) async {
    bool isCompleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Checkbox(
            value: isCompleted,
            onChanged: (value) {
              isCompleted = value!;
            },
          ),
        ),
      ),
    );

    // Нажимаем на чекбокс
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(isCompleted, true);
  });

  testWidgets('Basic widget test - TextField', (WidgetTester tester) async {
    String inputText = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            onChanged: (value) {
              inputText = value;
            },
          ),
        ),
      ),
    );

    // Вводим текст
    await tester.enterText(find.byType(TextField), 'Test Task');

    expect(inputText, 'Test Task');
  });

  testWidgets('Progress indicator displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinearProgressIndicator(
            value: 0.5,
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}