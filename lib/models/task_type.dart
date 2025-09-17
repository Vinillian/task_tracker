enum TaskType {
  stepByStep,
  checkbox;

  static TaskType fromString(String value) {
    switch (value) {
      case 'stepByStep':
        return TaskType.stepByStep;
      case 'checkbox':
        return TaskType.checkbox;
      default:
        return TaskType.stepByStep;
    }
  }

  @override
  String toString() {
    switch (this) {
      case TaskType.stepByStep:
        return 'stepByStep';
      case TaskType.checkbox:
        return 'checkbox';
    }
  }

  String get displayName {
    switch (this) {
      case TaskType.stepByStep:
        return 'Пошаговое выполнение';
      case TaskType.checkbox:
        return 'Чекбокс';
    }
  }
}