import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart';
import 'package:task_tracker/services/task_service.dart';
import 'package:task_tracker/services/hive_storage_service.dart';
import 'package:task_tracker/services/storage_service.dart';

// Вспомогательные функции для тестов
Project createTestProject({String id = '1', String name = 'Test Project'}) {
  return Project(
    id: id,
    name: name,
    description: 'Test Description',
    createdAt: DateTime.now(),
  );
}

Task createTestTask({
  String id = '1',
  String projectId = 'project_1',
  String title = 'Test Task',
  bool isCompleted = false,
  TaskType type = TaskType.single,
  int totalSteps = 1,
  int completedSteps = 0,
  String? parentId,
  int? color,
  int? priority,
  int? estimatedMinutes,
  DateTime? dueDate,
  bool isRecurring = false,
  DateTime? lastCompletedDate,
}) {
  return Task(
    id: id,
    projectId: projectId,
    title: title,
    description: 'Test Description',
    isCompleted: isCompleted,
    type: type,
    totalSteps: totalSteps,
    completedSteps: completedSteps,
    parentId: parentId,
    color: color,
    priority: priority,
    estimatedMinutes: estimatedMinutes,
    dueDate: dueDate,
    isRecurring: isRecurring,
    lastCompletedDate: lastCompletedDate,
  );
}

// Mock классы
class MockTaskService extends Mock implements TaskService {}

class MockHiveStorageService extends Mock implements HiveStorageService {}

class MockStorageService extends Mock implements StorageService {}

class MockWidgetRef extends Mock implements WidgetRef {}

// Test wrapper
class TestWrapper extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;

  const TestWrapper({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }
}

// Setup common mocks
void setupStorageServiceMocks(MockHiveStorageService mockStorageService) {
  when(() => mockStorageService.init()).thenAnswer((_) async {});
  when(() => mockStorageService.loadProjects()).thenAnswer((_) async => []);
  when(() => mockStorageService.saveProjects(any())).thenAnswer((_) async {});
  when(() => mockStorageService.clear()).thenAnswer((_) async {});
  when(() => mockStorageService.close()).thenAnswer((_) async {});
  when(() => mockStorageService.loadTasks()).thenAnswer((_) async => []);
  when(() => mockStorageService.saveTasks(any())).thenAnswer((_) async {});
}

void setupTaskServiceMocks(MockTaskService mockTaskService) {
  when(() => mockTaskService.getAllTasks()).thenReturn([]);
  when(() => mockTaskService.getProjectTasks(any())).thenReturn([]);
  when(() => mockTaskService.getSubTasks(any())).thenReturn([]);
  when(() => mockTaskService.getProjectProgress(any())).thenReturn(0.0);
  when(() => mockTaskService.getProjectTotalTasks(any())).thenReturn(0);
  when(() => mockTaskService.getProjectCompletedTasks(any())).thenReturn(0);
  when(() => mockTaskService.canAddSubTask(any())).thenReturn(true);
  when(() => mockTaskService.loadTasksFromStorage()).thenAnswer((_) async {});
  when(() => mockTaskService.getTaskById(any())).thenReturn(null);
}

// Fake classes for fallback values
class TaskFake extends Fake implements Task {}

class ProjectFake extends Fake implements Project {}

// Setup fallback values for mocktail
void setupFallbackValues() {
  registerFallbackValue(TaskFake());
  registerFallbackValue(ProjectFake());
  // TaskType - это enum, не нуждается в fallback value
}
