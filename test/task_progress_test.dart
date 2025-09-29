import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import '../lib/models/app_user.dart';
import '../lib/models/project.dart';
import '../lib/models/task.dart';
import '../lib/models/recurrence.dart';
import '../lib/models/recurrence_completion.dart';  // Импортируйте здесь адаптер Hive
import '../lib/repositories/local_repository.dart';
import '../lib/screens/calendar_screen.dart';
import '../lib/screens/planning_calendar_screen.dart';

late Directory tempDir;

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();

    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);

    Hive.registerAdapter(RecurrenceCompletionAdapter());

    if (!Hive.isBoxOpen('recurrenceCompletions')) {
      await Hive.openBox<RecurrenceCompletion>('recurrenceCompletions');
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  late LocalRepository localRepository;

  setUp(() {
    localRepository = LocalRepository();
  });

  final testUser = AppUser(
    username: 'testuser',
    email: 'test@example.com',
    projects: [
      Project(
        name: 'Test Project',
        tasks: [
          Task(
            name: 'Daily Single',
            totalSteps: 1,
            taskType: 'singleStep',
            recurrence: Recurrence(type: RecurrenceType.daily),
            plannedDate: DateTime.now(),
          ),
          Task(
            name: 'Daily StepByStep',
            totalSteps: 3,
            taskType: 'stepByStep',
            recurrence: Recurrence(type: RecurrenceType.daily),
            plannedDate: DateTime.now(),
          ),
          Task(
            name: 'Non-Daily Single',
            totalSteps: 1,
            taskType: 'singleStep',
            recurrence: Recurrence(type: RecurrenceType.weekly),
            plannedDate: DateTime.now(),
          ),
          Task(
            name: 'Non-Daily StepByStep',
            totalSteps: 4,
            taskType: 'stepByStep',
            recurrence: Recurrence(type: RecurrenceType.weekly),
            plannedDate: DateTime.now(),
          ),
        ],
      ),
    ],
    progressHistory: [],
  );

  testWidgets('CalendarScreen displays user tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalRepository>.value(value: localRepository),
        ],
        child: MaterialApp(
          home: CalendarScreen(
            currentUser: testUser,
            onItemCompleted: (item) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Daily Single'), findsWidgets);
    expect(find.text('Daily StepByStep'), findsWidgets);
    expect(find.text('Non-Daily Single'), findsWidgets);
    expect(find.text('Non-Daily StepByStep'), findsWidgets);
  });

  testWidgets('PlanningCalendarScreen displays user tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalRepository>.value(value: localRepository),
        ],
        child: MaterialApp(
          home: PlanningCalendarScreen(
            currentUser: testUser,
            onItemCompleted: (item) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Daily Single'), findsWidgets);
    expect(find.text('Daily StepByStep'), findsWidgets);
    expect(find.text('Non-Daily Single'), findsWidgets);
    expect(find.text('Non-Daily StepByStep'), findsWidgets);
  });
}
