// test/all_tests.dart
import 'smoke_test.dart' as smoke_test;
import 'basic_task_test.dart' as basic_task_test;
import 'project_progress_test.dart' as project_progress_test;
import 'task_execution_test.dart' as task_execution_test;
import 'calendar_planning_integration_test.dart' as calendar_planning_test;
import 'fake_progress_test.dart' as fake_progress_test;

void main() {
  smoke_test.main();
  basic_task_test.main();
  project_progress_test.main();
  task_execution_test.main();
  calendar_planning_test.main();
  fake_progress_test.main();
}