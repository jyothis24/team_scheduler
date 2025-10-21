import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../domain/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../../availability/presentation/pages/availability_page.dart';
import '../pages/task_creation_page.dart';
import 'task_list_state.dart';

class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(this._taskRepository, this._currentUserId)
      : super(const TaskListInitial()) {
    log('🏗️ TaskListCubit initialized with user: $_currentUserId');
    _loadTasks();
  }

  final TaskRepository _taskRepository;
  final String _currentUserId;

  String _selectedFilter = 'All';

  void _loadTasks() async {
    try {
      log('📋 Loading tasks...');
      log('👤 Current user ID: $_currentUserId');
      log('🔍 Selected filter: $_selectedFilter');
      emit(const TaskListLoading());

      List<Task> tasks = [];

      switch (_selectedFilter) {
        case 'Created':
          tasks = await _taskRepository.getTasksByUser(_currentUserId);
          break;
        case 'Mine':
          tasks = await _taskRepository.getTasksByCollaborator(_currentUserId);
          break;
        case 'All':
        default:
          tasks = await _taskRepository.getAllTasks();
          break;
      }

      emit(TaskListLoaded(
        tasks: tasks,
        selectedFilter: _selectedFilter,
        currentUserId: _currentUserId,
      ));
      log('✅ Tasks loaded: ${tasks.length} tasks');
    } catch (e) {
      log('❌ Failed to load tasks: $e');
      emit(TaskListError(message: 'Failed to load tasks: $e'));
    }
  }

  void changeFilter(String filter) {
    log('🔄 Changing filter to: $filter');
    _selectedFilter = filter;
    _loadTasks();
  }

  void addTask(BuildContext context) {
    log('➕ Add task button pressed');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskCreationPage(userId: _currentUserId),
      ),
    );
  }

  void manageSlots(BuildContext context) {
    log('📅 Manage slots button pressed');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AvailabilityPage(userId: _currentUserId),
      ),
    );
  }

  void refreshTasks() {
    log('🔄 Refreshing tasks...');
    _loadTasks();
  }

  void clearError() {
    log('🔄 Clearing error, returning to initial state');
    emit(const TaskListInitial());
    _loadTasks();
  }

  /// Creates a new task
  Future<void> createTask({
    required String title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? collaborators,
  }) async {
    try {
      log('➕ Creating new task: "$title"');
      emit(const TaskListLoading());

      await _taskRepository.createTask(
        title: title,
        description: description,
        createdBy: _currentUserId,
        startTime: startTime,
        endTime: endTime,
        collaborators: collaborators,
      );

      log('✅ Task created successfully');
      _loadTasks(); // Reload tasks to show the new one
    } catch (e) {
      log('❌ Failed to create task: $e');
      emit(TaskListError(message: 'Failed to create task: $e'));
    }
  }

  /// Updates an existing task
  Future<void> updateTask({
    required int taskId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? collaborators,
  }) async {
    try {
      log('✏️ Updating task: $taskId');
      emit(const TaskListLoading());

      await _taskRepository.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        collaborators: collaborators,
      );

      log('✅ Task updated successfully');
      _loadTasks(); // Reload tasks to show the updated one
    } catch (e) {
      log('❌ Failed to update task: $e');
      emit(TaskListError(message: 'Failed to update task: $e'));
    }
  }

  /// Deletes a task
  Future<void> deleteTask(int taskId) async {
    try {
      log('🗑️ Deleting task: $taskId');
      emit(const TaskListLoading());

      await _taskRepository.deleteTask(taskId);

      log('✅ Task deleted successfully');
      _loadTasks(); // Reload tasks to remove the deleted one
    } catch (e) {
      log('❌ Failed to delete task: $e');
      emit(TaskListError(message: 'Failed to delete task: $e'));
    }
  }

  /// Searches tasks by title
  Future<void> searchTasks(String query) async {
    try {
      log('🔍 Searching tasks: "$query"');
      emit(const TaskListLoading());

      final tasks = await _taskRepository.searchTasksByTitle(query);

      emit(TaskListLoaded(
        tasks: tasks,
        selectedFilter: _selectedFilter,
        currentUserId: _currentUserId,
      ));
      log('✅ Search completed: ${tasks.length} tasks found');
    } catch (e) {
      log('❌ Failed to search tasks: $e');
      emit(TaskListError(message: 'Failed to search tasks: $e'));
    }
  }
}
