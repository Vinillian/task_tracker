import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Добавьте этот импорт
import 'screens/task_tracker_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Добавьте эту строку
  await initializeDateFormatting('ru_RU', null); // Инициализация для русского языка
  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Трекер задач с подзадачами',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskTrackerScreen(),
    );
  }
}