// // screens/task_management_screen.dart
// import 'package:flutter/material.dart';
// import '../models/task.dart';
// import '../models/task_type.dart';
// import '../widgets/expandable_task_card.dart'; // ✅ ЗАМЕНИТЬ ИМПОРТ
// import '../widgets/add_task_dialog.dart';
// import '../widgets/edit_dialogs.dart';
// import '../models/task_type.dart';
//
// class TaskManagementScreen extends StatefulWidget {
//   final Task task;
//   final Function(Task) onTaskUpdated;
//   final Function()? onTaskDeleted;
//
//   const TaskManagementScreen({
//     super.key,
//     required this.task,
//     required this.onTaskUpdated,
//     this.onTaskDeleted,
//   });
//
//   @override
//   State<TaskManagementScreen> createState() => _TaskManagementScreenState();
// }
//
// class _TaskManagementScreenState extends State<TaskManagementScreen> {
//   late Task _task;
//
//   @override
//   void initState() {
//     super.initState();
//     _task = widget.task;
//   }
//
//   void _addSubTask() {
//     showDialog(
//       context: context,
//       builder: (context) => AddTaskDialog(
//         onTaskCreated: (String title, String description, TaskType type, int steps) {
//           _createSubTask(title, description, type, steps);
//         },
//       ),
//     );
//   }
//
//   void _createSubTask(String title, String description, TaskType type, int totalSteps) {
//     if (!_task.canAddSubTask) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Достигнут максимальный уровень вложенности!'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     setState(() {
//       final newSubTask = Task(
//         id: '${_task.id}_${DateTime.now().millisecondsSinceEpoch}',
//         title: title,
//         description: description,
//         isCompleted: false,
//         type: type,
//         totalSteps: totalSteps,
//         completedSteps: 0,
//         maxDepth: _task.maxDepth,
//       );
//
//       _task = _task.copyWith(
//         subTasks: [..._task.subTasks, newSubTask],
//       );
//     });
//
//     widget.onTaskUpdated(_task);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Подзадача "$title" добавлена!'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   void _updateSubTaskWithNested(int subTaskIndex, Task updatedSubTask) {
//     setState(() {
//       final updatedSubTasks = List<Task>.from(_task.subTasks);
//       updatedSubTasks[subTaskIndex] = updatedSubTask;
//       _task = _task.copyWith(subTasks: updatedSubTasks);
//     });
//
//     widget.onTaskUpdated(_task);
//   }
//
//   void _deleteSubTask(int subTaskIndex) {
//     setState(() {
//       final updatedSubTasks = List<Task>.from(_task.subTasks)..removeAt(subTaskIndex);
//       _task = _task.copyWith(subTasks: updatedSubTasks);
//     });
//
//     widget.onTaskUpdated(_task);
//   }
//
//   void _editTask() {
//     showDialog(
//       context: context,
//       builder: (context) => EditTaskDialog(
//         task: _task,
//         onTaskUpdated: (String title, String description) {
//           setState(() {
//             _task = _task.copyWith(
//               title: title,
//               description: description,
//             );
//           });
//           widget.onTaskUpdated(_task);
//         },
//       ),
//     );
//   }
//
//   Widget _buildTaskHeader() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 _buildTaskIcon(),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _task.title,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit, color: Colors.orange),
//                   onPressed: _editTask,
//                   tooltip: 'Редактировать задачу',
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             if (_task.description.isNotEmpty) ...[
//               Text(
//                 _task.description,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             _buildTaskProgress(),
//             const SizedBox(height: 8),
//             _buildTaskStats(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTaskIcon() {
//     if (_task.type == TaskType.stepByStep) {
//       return const Icon(Icons.linear_scale, color: Colors.purple, size: 28);
//     } else {
//       return Icon(
//         _task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
//         color: _task.isCompleted ? Colors.green : Colors.blue,
//         size: 28,
//       );
//     }
//   }
//
//   Widget _buildTaskProgress() {
//     return Row(
//       children: [
//         Expanded(
//           child: LinearProgressIndicator(
//             value: _task.progress,
//             backgroundColor: Colors.grey.shade200,
//             color: _task.progress == 1.0 ? Colors.green : Colors.blue,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Text(
//           '${(_task.progress * 100).toInt()}%',
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTaskStats() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           'Подзадачи: ${_task.subTasks.length}',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey.shade600,
//           ),
//         ),
//         if (_task.type == TaskType.stepByStep)
//           Text(
//             'Шаги: ${_task.completedSteps}/${_task.totalSteps}',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         Text(
//           'Уровень: ${_task.calculateDepth() + 1}',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey.shade600,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSubTasksList() {
//     if (_task.subTasks.isEmpty) {
//       return const Expanded(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.subdirectory_arrow_right, size: 64, color: Colors.grey),
//               SizedBox(height: 16),
//               Text(
//                 'Нет подзадач',
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 'Добавьте подзадачи для детализации',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Expanded(
//       child: ListView.builder(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: _task.subTasks.length,
//         itemBuilder: (context, index) {
//           final subTask = _task.subTasks[index];
//
//           return ExpandableTaskCard( // ✅ ИСПОЛЬЗУЕМ НОВЫЙ ВИДЖЕТ
//             task: subTask,
//             taskIndex: index,
//             onTaskUpdated: (updatedTask) => _updateSubTaskWithNested(index, updatedTask),
//             onTaskDeleted: () => _deleteSubTask(index),
//             level: 1, // Начинаем с уровня 1 (подзадачи)
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Управление задачей'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           if (_task.canAddSubTask) ...[
//             IconButton(
//               icon: const Icon(Icons.add),
//               onPressed: _addSubTask,
//               tooltip: 'Добавить подзадачу',
//             ),
//           ],
//           if (widget.onTaskDeleted != null) ...[
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () {
//                 widget.onTaskDeleted!();
//                 Navigator.pop(context);
//               },
//               tooltip: 'Удалить задачу',
//             ),
//           ],
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildTaskHeader(),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Text(
//                   'Подзадачи',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Icon(Icons.subdirectory_arrow_right, size: 16),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           _buildSubTasksList(),
//         ],
//       ),
//       floatingActionButton: _task.canAddSubTask
//           ? FloatingActionButton(
//         onPressed: _addSubTask,
//         child: const Icon(Icons.add),
//       )
//           : null,
//     );
//   }
// }