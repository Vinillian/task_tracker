import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';

void main() {  // ✅ ДОБАВИТЬ main функцию
  group('Task Depth Calculation Tests', () {
    test('Calculate depth for flat task', () {
      final task = Task(id: '1', title: 'Flat Task', description: '');
      expect(task.calculateDepth(), 0);
    });

    test('Calculate depth for one level nesting', () {
      final task = Task(
        id: '1',
        title: 'Parent Task',
        description: '',
        subTasks: [
          Task(id: '1-1', title: 'Child Task', description: ''),
        ],
      );
      expect(task.calculateDepth(), 1);
    });

    test('Calculate depth for deep nesting', () {
      final deepTask = Task(
        id: '1',
        title: 'Level 0',
        description: '',
        subTasks: [
          Task(
            id: '1-1',
            title: 'Level 1',
            description: '',
            subTasks: [
              Task(
                id: '1-1-1',
                title: 'Level 2',
                description: '',
                subTasks: [
                  Task(id: '1-1-1-1', title: 'Level 3', description: ''),
                ],
              ),
            ],
          ),
        ],
      );
      expect(deepTask.calculateDepth(), 3);
    });

    test('Can add subtask check works correctly', () {
      final taskAtMaxDepth = Task(
        id: '1',
        title: 'Task',
        description: '',
        maxDepth: 2,
        subTasks: [
          Task(
            id: '1-1',
            title: 'Level 1',
            description: '',
            subTasks: [
              Task(id: '1-1-1', title: 'Level 2', description: ''),
            ],
          ),
        ],
      );

      expect(taskAtMaxDepth.canAddSubTask, false);

      final taskCanAdd = Task(
        id: '2',
        title: 'Task',
        description: '',
        maxDepth: 3,
        subTasks: [],
      );

      expect(taskCanAdd.canAddSubTask, true);
    });
  });
}