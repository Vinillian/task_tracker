class Subtask {
  String name;
  int completedSteps;
  int totalSteps;

  Subtask({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
    };
  }

  static Subtask fromFirestore(Map<String, dynamic> data) {
    return Subtask(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
    );
  }
}
