// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== USER METHODS ==========
  Future<void> saveUser(AppUser user) {
    return _db.collection('users').doc(user.id).set(user.toJson());
  }

  Stream<AppUser?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<AppUser?> getUserDocument(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromJson(doc.data()!);
    }
    return null;
  }

  // ========== PROJECT METHODS ==========
  Stream<List<Project>> watchProjects() {
    return _db.collection('projects').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) {
          final project = Project.fromJson(doc.data());
          return project.copyWith(id: doc.id);
        }).toList());
  }

  Future<void> addProject(Project project) {
    return _db.collection('projects').add(project.toJson());
  }

  Future<void> updateProject(Project project) {
    return _db.collection('projects').doc(project.id).update(project.toJson());
  }

  Future<void> deleteProject(String projectId) async {
    // Delete all project tasks first
    final tasksSnapshot = await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .get();

    final batch = _db.batch();
    for (final doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Then delete the project
    await _db.collection('projects').doc(projectId).delete();
  }

  // ========== TASK METHODS ==========
  Stream<List<Task>> watchProjectTasks(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .where('parentTaskId', isEqualTo: null)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final task = Task.fromJson(doc.data());
      return task.copyWith(id: doc.id);
    }).toList());
  }

  Stream<List<Task>> watchSubTasks(String projectId, String parentTaskId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .where('parentTaskId', isEqualTo: parentTaskId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final task = Task.fromJson(doc.data());
      return task.copyWith(id: doc.id);
    }).toList());
  }

  Stream<List<Task>> watchAllProjectTasks(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final task = Task.fromJson(doc.data());
      return task.copyWith(id: doc.id);
    }).toList());
  }

  Future<String> addTask(String projectId, Task task) async {
    final docRef = await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add(task.toJson());
    return docRef.id;
  }

  Future<void> updateTask(String projectId, Task task) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(task.id)
        .update(task.toJson());
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    final tasksRef = _db.collection('projects').doc(projectId).collection('tasks');

    // Find all subtasks
    final subTasksSnapshot = await tasksRef.where('parentTaskId', isEqualTo: taskId).get();

    // Recursively delete subtasks
    for (final doc in subTasksSnapshot.docs) {
      await deleteTask(projectId, doc.id);
    }

    // Delete the task itself
    await tasksRef.doc(taskId).delete();
  }

  Future<Task?> getTask(String projectId, String taskId) async {
    final doc = await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .get();

    if (doc.exists) {
      final task = Task.fromJson(doc.data()!);
      return task.copyWith(id: doc.id);
    }
    return null;
  }

  Future<void> moveTask(String projectId, String taskId, String? newParentTaskId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({'parentTaskId': newParentTaskId});
  }
}