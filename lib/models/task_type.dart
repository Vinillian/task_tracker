enum TaskType {
  single,     // Одиночная задача
  multiStep,  // Многошаговая (теперь через subtasks)
  recurring,  // Повторяющаяся
}

extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.single:
        return 'Одиночная';
      case TaskType.multiStep:
        return 'Многошаговая';
      case TaskType.recurring:
        return 'Повторяющаяся';
    }
  }

  String get description {
    switch (this) {
      case TaskType.single:
        return 'Простая задача без подзадач';
      case TaskType.multiStep:
        return 'Задача с вложенными подзадачами';
      case TaskType.recurring:
        return 'Повторяющаяся задача';
    }
  }

  bool get canHaveSubtasks {
    return this == TaskType.multiStep;
  }

  bool get isRecurring {
    return this == TaskType.recurring;
  }
}