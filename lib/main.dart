import 'package:flutter/material.dart';
import 'screens/task_tracker_screen.dart';

void main() {
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