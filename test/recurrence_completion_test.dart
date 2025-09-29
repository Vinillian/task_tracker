import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import '../lib/models/task.dart';
import '../lib/models/recurrence_completion.dart';  //  <-- ВАЖНО!
import '../lib/repositories/local_repository.dart';
import '../lib/services/recurrence_completion_service.dart';

late Directory tempDir;   // Объявить tempDir вне main

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();

    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);

    Hive.registerAdapter(RecurrenceCompletionAdapter());  // Обязательно зарегистрировать адаптер

    if (!Hive.isBoxOpen('recurrenceCompletions')) {
      await Hive.openBox<RecurrenceCompletion>('recurrenceCompletions');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('RecurrenceCompletionService mark and check completion', (WidgetTester tester) async {
    final task = Task(
      name: 'Test Task',
      totalSteps: 1,
      completedSteps: 0,
      taskType: 'stepByStep',
      isCompleted: false,
    );

    final localRepository = LocalRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalRepository>.value(value: localRepository),
        ],
        child: Builder(builder: (BuildContext context) {
          return const SizedBox.shrink();
        }),
      ),
    );

    final now = DateTime.now();

    await tester.runAsync(() async {
      await RecurrenceCompletionService.markOccurrenceCompleted(task, now, tester.element(find.byType(SizedBox)));
      final isCompleted = await RecurrenceCompletionService.isOccurrenceCompleted(task, now, tester.element(find.byType(SizedBox)));
      expect(isCompleted, true);
    });

    await tester.pumpAndSettle();
  });
}
