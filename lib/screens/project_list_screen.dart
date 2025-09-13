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

    print('💾 Сохранение пользователя: ${currentUser!.username}');
    print('📊 Проектов: ${currentUser!.projects.length}');

    onUserChanged(currentUser);
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
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: Text(
              project.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Задач: ${project.tasks.length}'),
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
              icon: const Icon(Icons.delete, color: Colors.red),
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
          ),
        );
      },
    );
  }
}