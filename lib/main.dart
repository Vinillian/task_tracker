// main.dart
import 'package:flutter/material.dart';
import 'screens/task_tracker_screen.dart'; // Убедитесь что этот импорт есть

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TaskTrackerScreen(), // Главный экран
    );
  }
}