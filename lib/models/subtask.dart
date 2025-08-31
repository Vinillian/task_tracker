class Subtask {
  String name;
  int totalSteps;
  int completedSteps;

  Subtask({
    required this.name,
    required this.totalSteps,
    required this.completedSteps,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'totalSteps': totalSteps,
    'completedSteps': completedSteps,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      name: json['name'],
      totalSteps: json['totalSteps'],
      completedSteps: json['completedSteps'],
    );
  }
}