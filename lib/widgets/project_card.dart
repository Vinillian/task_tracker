// // widgets/project_card.dart - ПОЛНОСТЬЮ ПЕРЕПИСАТЬ
// import 'package:flutter/material.dart';
// import '../models/project.dart';
// import '../models/task.dart';
// import '../models/task_type.dart';
// import 'expandable_task_card.dart'; // ✅ Будем создавать этот виджет
// import 'add_task_dialog.dart';
// import 'edit_dialogs.dart';
//
// class ProjectCard extends StatefulWidget {
//   final Project project;
//   final int projectIndex;
//   final Function(Project) onUpdate;
//   final Function() onDelete;
//
//   const ProjectCard({
//     super.key,
//     required this.project,
//     required this.projectIndex,
//     required this.onUpdate,
//     required this.onDelete,
//   });
//
//   @override
//   State<ProjectCard> createState() => _ProjectCardState();
// }
//
// class _ProjectCardState extends State<ProjectCard> {
//   void _addTask() {
//     showDialog(
//       context: context,
//       builder: (context) => AddTaskDialog(
//         onTaskCreated: (String title, String description, TaskType type, int steps) {
//           _createTask(title, description, type, steps);
//         },
//       ),
//     );
//   }
//
//   void _createTask(String title, String description, TaskType type, int totalSteps) {
//     final newTask = Task(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: title,
//       description: description,
//       isCompleted: false,
//       type: type,
//       totalSteps: totalSteps,
//       completedSteps: 0,
//     );
//
//     final updatedProject = widget.project.copyWith(
//       tasks: [...widget.project.tasks, newTask],
//     );
//
//     widget.onUpdate(updatedProject);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Задача "$title" добавлена!'),
//         backgroundColor: Colors.blue,
//       ),
//     );
//   }
//
//   void _updateTaskWithSubTasks(int taskIndex, Task updatedTask) {
//     final updatedTasks = List<Task>.from(widget.project.tasks);
//     updatedTasks[taskIndex] = updatedTask;
//     final updatedProject = widget.project.copyWith(tasks: updatedTasks);
//     widget.onUpdate(updatedProject);
//   }
//
//   void _deleteTask(int taskIndex) {
//     final updatedTasks = List<Task>.from(widget.project.tasks)..removeAt(taskIndex);
//     final updatedProject = widget.project.copyWith(tasks: updatedTasks);
//     widget.onUpdate(updatedProject);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Заголовок проекта
//             Row(
//               children: [
//                 const Icon(Icons.folder, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     widget.project.name,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit, color: Colors.orange),
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => EditProjectDialog(
//                         project: widget.project,
//                         onProjectUpdated: (String name, String description) {
//                           final updatedProject = widget.project.copyWith(
//                             name: name,
//                             description: description,
//                           );
//                           widget.onUpdate(updatedProject);
//                         },
//                       ),
//                     );
//                   },
//                   tooltip: 'Редактировать проект',
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add_task, color: Colors.green),
//                   onPressed: _addTask,
//                   tooltip: 'Добавить задачу',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               widget.project.description,
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 12),
//
//             // Прогресс проекта
//             Row(
//               children: [
//                 Expanded(
//                   child: LinearProgressIndicator(
//                     value: widget.project.progress,
//                     backgroundColor: Colors.grey.shade200,
//                     color: widget.project.progress == 1.0 ? Colors.green : Colors.blue,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   '${(widget.project.progress * 100).toInt()}%',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Прогресс учитывает все задачи и подзадачи',
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Colors.grey.shade500,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '${widget.project.completedTasks}/${widget.project.totalTasks} задач выполнено',
//               style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//             ),
//
//             const SizedBox(height: 16),
//             const Text(
//               'Задачи проекта:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//
//             // ✅ ТОЛЬКО ПРЯМЫЕ ЗАДАЧИ ПРОЕКТА С ВОЗМОЖНОСТЬЮ РАСКРЫТИЯ
//             ...widget.project.tasks.asMap().entries.map((entry) {
//               final taskIndex = entry.key;
//               final task = entry.value;
//
//               return ExpandableTaskCard(
//                 task: task,
//                 taskIndex: taskIndex,
//                 onTaskUpdated: (updatedTask) => _updateTaskWithSubTasks(taskIndex, updatedTask),
//                 onTaskDeleted: () => _deleteTask(taskIndex),
//                 level: 0, // Уровень вложенности (0 - корневой)
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }
// }