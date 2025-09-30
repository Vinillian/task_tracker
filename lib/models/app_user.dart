// lib/models/app_user.dart
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final bool isCompleted;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    required this.isCompleted,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}