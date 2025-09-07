import 'package:flutter/material.dart';
import '../models/user.dart';
import './project_widgets.dart';
import '../models/progress_history.dart';

class TaskWidgets {
  static Widget buildTasksTab({
    required List<User> users,
    required User? currentUser,
    required bool showUserInput,
    required TextEditingController userController,
    required TextEditingController projectController,
    required bool showProjectInput,
    required Map<int, bool> showTaskInput,
    required Map<String, bool> showSubtaskInput,
    required Function(User?) onUserChanged,
    required Function(bool) onShowUserInputChanged,
    required Function(bool) onShowProjectInputChanged,
    required Function(int, bool) onShowTaskInputChanged,
    required Function(String, bool) onShowSubtaskInputChanged,
    required Function() onAddUser,
    required Function() onAddProject,
    required TextEditingController Function(int) getTaskNameController,
    required TextEditingController Function(int) getTaskStepsController,
    required TextEditingController Function(int, int) getSubtaskNameController,
    required TextEditingController Function(int, int) getSubtaskStepsController,
    required Function(int) onAddTask,
    required Function(int, int) onAddSubtask,
    required Function(int, int, int) onAddIncrementalProgress,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Пользователь:'),
              const SizedBox(width: 8),
              DropdownButton<User>(
                value: currentUser,
                items: users.map<DropdownMenuItem<User>>((user) {
                  return DropdownMenuItem(value: user, child: Text(user.name));
                }).toList(),
                onChanged: onUserChanged,
              ),
              const SizedBox(width: 16),
              if (!showUserInput)
                ElevatedButton(
                  onPressed: () => onShowUserInputChanged(true),
                  child: const Text('+ Новый пользователь'),
                ),
            ],
          ),
        ),

        if (showUserInput)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      hintText: 'Имя пользователя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAddUser,
                  child: const Text('Добавить'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onShowUserInputChanged(false),
                ),
              ],
            ),
          ),

        if (currentUser != null) _buildUserContent(
          currentUser: currentUser,
          projectController: projectController,
          showProjectInput: showProjectInput,
          showTaskInput: showTaskInput,
          showSubtaskInput: showSubtaskInput,
          onShowProjectInputChanged: onShowProjectInputChanged,
          onShowTaskInputChanged: onShowTaskInputChanged,
          onShowSubtaskInputChanged: onShowSubtaskInputChanged,
          onAddProject: onAddProject,
          getTaskNameController: getTaskNameController,
          getTaskStepsController: getTaskStepsController,
          getSubtaskNameController: getSubtaskNameController,
          getSubtaskStepsController: getSubtaskStepsController,
          onAddTask: onAddTask,
          onAddSubtask: onAddSubtask,
          onAddIncrementalProgress: onAddIncrementalProgress,
        ),
        if (currentUser == null && !showUserInput)
          const Expanded(child: Center(child: Text('Добавьте пользователя'))),
      ],
    );
  }

  static Widget _buildUserContent({
    required User currentUser,
    required TextEditingController projectController,
    required bool showProjectInput,
    required Map<int, bool> showTaskInput,
    required Map<String, bool> showSubtaskInput,
    required Function(bool) onShowProjectInputChanged,
    required Function(int, bool) onShowTaskInputChanged,
    required Function(String, bool) onShowSubtaskInputChanged,
    required Function() onAddProject,
    required TextEditingController Function(int) getTaskNameController,
    required TextEditingController Function(int) getTaskStepsController,
    required TextEditingController Function(int, int) getSubtaskNameController,
    required TextEditingController Function(int, int) getSubtaskStepsController,
    required Function(int) onAddTask,
    required Function(int, int) onAddSubtask,
    required Function(int, int, int) onAddIncrementalProgress,
  }) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (!showProjectInput)
                  ElevatedButton(
                    onPressed: () => onShowProjectInputChanged(true),
                    child: const Text('+ Новый проект'),
                  ),
              ],
            ),
          ),

          if (showProjectInput)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: projectController,
                      decoration: const InputDecoration(
                        hintText: 'Название проекта',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAddProject,
                    child: const Text('Добавить'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onShowProjectInputChanged(false),
                  ),
                ],
              ),
            ),

          Expanded(
            child: currentUser.projects.isEmpty
                ? const Center(child: Text('Добавьте проект'))
                : ListView.builder(
              itemCount: currentUser.projects.length,
              itemBuilder: (context, projectIndex) {
                return ProjectWidgets.buildProjectItem(
                  project: currentUser.projects[projectIndex],
                  projectIndex: projectIndex,
                  showTaskInput: showTaskInput,
                  showSubtaskInput: showSubtaskInput,
                  onShowTaskInputChanged: onShowTaskInputChanged,
                  onShowSubtaskInputChanged: onShowSubtaskInputChanged,
                  getTaskNameController: getTaskNameController,
                  getTaskStepsController: getTaskStepsController,
                  getSubtaskNameController: getSubtaskNameController,
                  getSubtaskStepsController: getSubtaskStepsController,
                  onAddTask: onAddTask,
                  onAddSubtask: onAddSubtask,
                  onAddIncrementalProgress: onAddIncrementalProgress,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}