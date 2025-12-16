import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';
import 'data/services/hive_storage_service.dart';
import 'shared/utils/logger.dart';
import 'presentation/providers/project_provider.dart';
import 'presentation/screens/test_lab_screen.dart';
import 'data/repositories/hive_project_repository.dart';
import 'data/repositories/hive_task_repository.dart';
import 'shared/services/navigation_service.dart';
import 'presentation/providers/task_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = HiveStorageService();
  await storageService.init();
  Logger.success('Hive storage initialized successfully');

  runApp(ProviderScope(
    overrides: [
      projectRepositoryProvider
          .overrideWithValue(HiveProjectRepository(storageService)),
      taskRepositoryProvider.overrideWithValue(
          HiveTaskRepository(storageService)), // ✅ ИСПРАВЛЕНО
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: NavigationService.navigatorKey,
      home: const HomeScreen(),
      routes: {
        '/test-lab': (context) => const TestLabScreen(),
      },
    );
  }
}
