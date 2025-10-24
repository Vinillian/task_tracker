import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'services/hive_storage_service.dart';
import 'utils/logger.dart';
import 'providers/project_provider.dart'; // ✅ ДОБАВИТЬ импорт
import 'screens/test_lab_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализируем Hive ДО создания провайдеров
  final storageService = HiveStorageService();
  await storageService.init();
  Logger.success('Hive storage initialized successfully');

  runApp(ProviderScope(
    overrides: [
      // ✅ Передаем инициализированный storageService в провайдеры
      storageServiceProvider.overrideWithValue(storageService),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // В методе build класса MyApp, в return MaterialApp(...)
    return MaterialApp(
      title: 'Task Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      routes: {
        '/test-lab': (context) => const TestLabScreen(), // ДОБАВИТЬ эту строку
      },
    );
  }
}
