enum TaskType {
  stepByStep,
  singleStep;

  static TaskType fromString(String value) {
    switch (value) {
      case 'stepByStep':
        return TaskType.stepByStep;
      case 'singleStep':
        return TaskType.singleStep;
      default:
        return TaskType.stepByStep;
    }
  }

  @override
  String toString() {
    switch (this) {
      case TaskType.stepByStep:
        return 'stepByStep';
      case TaskType.singleStep:
        return 'singleStep';
    }
  }

  String get displayName {
    switch (this) {
      case TaskType.stepByStep:
        return 'Пошаговая';
      case TaskType.singleStep:
        return 'Единовременная';
    }
  }

  String get description {
    switch (this) {
      case TaskType.stepByStep:
        return 'Задача выполняется постепенно через несколько шагов';
      case TaskType.singleStep:
        return 'Задача выполняется одним действием (чекбокс)';
    }
  }
}