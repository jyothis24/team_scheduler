import '../../domain/models/task.dart';

abstract class TaskListState {
  const TaskListState();
}

class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

class TaskListLoaded extends TaskListState {
  final List<Task> tasks;
  final String selectedFilter;
  final String? currentUserId;

  const TaskListLoaded({
    required this.tasks,
    this.selectedFilter = 'All',
    this.currentUserId,
  });

  TaskListLoaded copyWith({
    List<Task>? tasks,
    String? selectedFilter,
    String? currentUserId,
  }) {
    return TaskListLoaded(
      tasks: tasks ?? this.tasks,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class TaskListError extends TaskListState {
  final String message;

  const TaskListError({required this.message});
}
