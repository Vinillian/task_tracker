import 'package:flutter/material.dart';
import 'project.dart';
import 'progress_history.dart';

class User {
  String name;
  List<Project> projects;
  List<ProgressHistory> progressHistory;

  User({
    required this.name,
    required this.projects,
    required this.progressHistory,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'projects': projects.map((p) => p.toJson()).toList(),
    'progressHistory': progressHistory.map((h) => h.toJson()).toList(),
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      projects: (json['projects'] as List)
          .map((p) => Project.fromJson(p))
          .toList(),
      progressHistory:
      (json['progressHistory'] as List?)
          ?.map((h) => ProgressHistory.fromJson(h))
          .toList() ??
          [],
    );
  }
}