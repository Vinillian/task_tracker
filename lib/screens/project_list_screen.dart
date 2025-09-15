import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../widgets/dialogs.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatelessWidget {
  final AppUser? currentUser;
  final Function(AppUser?) onUserChanged;
  final Function() onAddProject;
  final Function(Project) onDeleteProject;
  final Function(String, int, String) onAddProgressHistory;

  const ProjectListScreen({
    super.key,
    required this.currentUser,
    required this.onUserChanged,
    required this.onAddProject,
    required this.onDeleteProject,
    required this.onAddProgressHistory,
  });

  void _saveCurrentUser() {
    if (currentUser == null) return;
    onUserChanged(currentUser);
  }

  // Новый метод для отображения прогресса проекта
  Widget _buildProjectProgress(Project project) {
    int completed = 0;
    int total = project.tasks.length;

    for (var task in project.tasks) {
      if (task.completedSteps >= task.totalSteps) completed++;
    }

    double progress = total > 0 ? completed / total : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          color: progress > 0.7 ? Colors.green : progress > 0.3 ? Colors.orange : Colors.red,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% завершено',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Добавьте первый проект'));
    }

    if (currentUser!.projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Нет проектов', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Нажмите + чтобы создать первый проект'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAddProject,
              child: const Text('Создать проект'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: currentUser!.projects.length,
      itemBuilder: (context, index) {
        final project = currentUser!.projects[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.folder, color: Colors.blue.shade700),
            ),
            title: Text(
              project.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${project.tasks.length} задач', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                if (project.tasks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildProjectProgress(project),
                ],
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailScreen(
                    project: project,
                    onProjectUpdated: (updatedProject) {
                      final updatedProjects = List<Project>.from(currentUser!.projects);
                      updatedProjects[index] = updatedProject;

                      final updatedUser = AppUser(
                        username: currentUser!.username,
                        email: currentUser!.email,
                        projects: updatedProjects,
                        progressHistory: List<dynamic>.from(currentUser!.progressHistory),
                      );

                      onUserChanged(updatedUser);
                      _saveCurrentUser();
                    },
                    onAddProgressHistory: onAddProgressHistory,
                  ),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade600),
              onPressed: () async {
                final confirm = await Dialogs.showConfirmDialog(
                  context: context,
                  title: 'Удалить проект',
                  message: 'Удалить проект "${project.name}"?',
                );
                if (confirm) {
                  onDeleteProject(project);
                  _saveCurrentUser();
                }
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }
}