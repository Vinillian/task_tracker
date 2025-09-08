import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../widgets/dialogs.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatelessWidget {
  final User? currentUser;
  final Function(User?) onUserChanged;
  final Function() onAddProject;
  final Function(Project) onDeleteProject;
  final Function(String, int, String) onAddProgressHistory;
  final FirestoreService _firestoreService = FirestoreService();

  ProjectListScreen({
    super.key,
    required this.currentUser,
    required this.onUserChanged,
    required this.onAddProject,
    required this.onDeleteProject,
    required this.onAddProgressHistory,
  });

  void _openProject(Project project) {
    // Этот метод будет использоваться когда будем переходить к деталям проекта
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Добавьте первый проект'));
    }

    // УБЕРИТЕ Column и ElevatedButton, оставьте только ListView
    return ListView.builder(
      itemCount: currentUser!.projects.length,
      itemBuilder: (context, index) {
        final project = currentUser!.projects[index];
        final totalSteps = project.tasks.fold<int>(0, (sum, task) => sum + task.totalSteps);
        final completedSteps = project.tasks.fold<int>(0, (sum, task) => sum + task.completedSteps);
        final progress = totalSteps > 0 ? completedSteps / totalSteps : 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getProjectProgressColor(progress.toDouble()),
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          title: Text(project.name),
          subtitle: Text('$completedSteps/$totalSteps шагов • ${project.tasks.length} задач'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailScreen(
                  project: project,
                  onProjectUpdated: (updatedProject) {
                    currentUser!.projects[index] = updatedProject;
                    _firestoreService.saveUser(currentUser!);
                    onUserChanged(currentUser);
                  },
                  onAddProgressHistory: onAddProgressHistory, // ДОБАВИТЬ
                ),
              ),
            );
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await Dialogs.showConfirmDialog(
                context: context,
                title: 'Удалить проект',
                message: 'Удалить проект "${project.name}"?',
              );
              if (confirm) onDeleteProject(project);
            },
          ),
        );
      },
    );
  }

  Color _getProjectProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.orange;
    if (progress >= 0.3) return Colors.yellow;
    return Colors.red;
  }
}