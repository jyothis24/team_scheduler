import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/task.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;

  /// Creates a new task in the database
  Future<Task> createTask({
    required String title,
    String? description,
    required String createdBy,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? collaborators,
  }) async {
    try {
      log('🔵 Creating new task with title: "$title"');

      // First create the task
      final taskData = {
        'title': title.trim(),
        'description': description?.trim(),
        'created_by': createdBy,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
      };

      final response =
          await _supabase.from('tasks').insert(taskData).select().single();

      log('✅ Task created successfully with ID: ${response['id']}');

      // Add collaborators if provided
      if (collaborators != null && collaborators.isNotEmpty) {
        await _addCollaborators(response['id'], collaborators);
      }

      // Fetch the complete task with collaborators
      final completeTask = await getTaskById(response['id']);
      return completeTask!;
    } catch (e) {
      log('❌ Failed to create task: $e');
      rethrow;
    }
  }

  /// Fetches all tasks with their collaborators
  Future<List<Task>> getAllTasks() async {
    try {
      log('🔵 Fetching all tasks...');

      final response = await _supabase
          .from('tasks')
          .select()
          .order('created_at', ascending: false);

      final List<Task> tasks = [];

      for (final taskData in response) {
        // Get collaborators for each task
        final collaborators = await _getTaskCollaborators(taskData['id']);

        final task = Task.fromJson({
          ...taskData,
          'collaborators': collaborators,
        });

        tasks.add(task);
      }

      log('✅ Successfully fetched ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      log('❌ Failed to fetch all tasks: $e');
      rethrow;
    }
  }

  /// Fetches a specific task by ID with collaborators
  Future<Task?> getTaskById(int taskId) async {
    try {
      log('🔵 Fetching task with ID: $taskId');

      final response =
          await _supabase.from('tasks').select().eq('id', taskId).maybeSingle();

      if (response == null) {
        log('⚠️ No task found with ID: $taskId');
        return null;
      }

      // Get collaborators for the task
      final collaborators = await _getTaskCollaborators(taskId);

      final task = Task.fromJson({
        ...response,
        'collaborators': collaborators,
      });

      log('✅ Task found with ID: $taskId');
      return task;
    } catch (e) {
      log('❌ Failed to fetch task by ID: $e');
      rethrow;
    }
  }

  /// Updates a task's information
  Future<Task> updateTask({
    required int taskId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? collaborators,
  }) async {
    try {
      log('🔵 Updating task with ID: $taskId');

      final Map<String, dynamic> updates = {};

      // Add fields to updates if provided
      if (title != null && title.trim().isNotEmpty) {
        updates['title'] = title.trim();
        log('📝 Updating title to: "$title"');
      }

      if (description != null) {
        updates['description'] = description.trim();
        log('📝 Updating description');
      }

      if (startTime != null) {
        updates['start_time'] = startTime.toIso8601String();
        log('📝 Updating start time');
      }

      if (endTime != null) {
        updates['end_time'] = endTime.toIso8601String();
        log('📝 Updating end time');
      }

      // Perform the update if there are changes
      if (updates.isNotEmpty) {
        await _supabase.from('tasks').update(updates).eq('id', taskId);
        log('✅ Task updated successfully');
      }

      // Update collaborators if provided
      if (collaborators != null) {
        await _updateTaskCollaborators(taskId, collaborators);
      }

      // Return the updated task
      final updatedTask = await getTaskById(taskId);
      return updatedTask!;
    } catch (e) {
      log('❌ Failed to update task: $e');
      rethrow;
    }
  }

  /// Deletes a task from the database
  Future<void> deleteTask(int taskId) async {
    try {
      log('🔵 Deleting task with ID: $taskId');

      // Delete collaborators first (due to foreign key constraints)
      await _supabase.from('task_collaborators').delete().eq('task_id', taskId);

      // Delete the task
      await _supabase.from('tasks').delete().eq('id', taskId);

      log('✅ Task deleted successfully');
    } catch (e) {
      log('❌ Failed to delete task: $e');
      rethrow;
    }
  }

  /// Gets tasks created by a specific user
  Future<List<Task>> getTasksByUser(String userId) async {
    try {
      log('🔵 Fetching tasks created by user: $userId');

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      final List<Task> tasks = [];

      for (final taskData in response) {
        final collaborators = await _getTaskCollaborators(taskData['id']);

        final task = Task.fromJson({
          ...taskData,
          'collaborators': collaborators,
        });

        tasks.add(task);
      }

      log('✅ Found ${tasks.length} tasks created by user: $userId');
      return tasks;
    } catch (e) {
      log('❌ Failed to fetch tasks by user: $e');
      rethrow;
    }
  }

  /// Gets tasks where user is a collaborator
  Future<List<Task>> getTasksByCollaborator(String userId) async {
    try {
      log('🔵 Fetching tasks where user is collaborator: $userId');

      final response = await _supabase
          .from('task_collaborators')
          .select('task_id')
          .eq('user_id', userId);

      final List<int> taskIds =
          response.map((item) => item['task_id'] as int).toList();

      if (taskIds.isEmpty) {
        log('✅ No tasks found for collaborator: $userId');
        return [];
      }

      final tasksResponse = await _supabase
          .from('tasks')
          .select()
          .inFilter('id', taskIds)
          .order('created_at', ascending: false);

      final List<Task> tasks = [];

      for (final taskData in tasksResponse) {
        final collaborators = await _getTaskCollaborators(taskData['id']);

        final task = Task.fromJson({
          ...taskData,
          'collaborators': collaborators,
        });

        tasks.add(task);
      }

      log('✅ Found ${tasks.length} tasks for collaborator: $userId');
      return tasks;
    } catch (e) {
      log('❌ Failed to fetch tasks by collaborator: $e');
      rethrow;
    }
  }

  /// Searches tasks by title (case-insensitive partial match)
  Future<List<Task>> searchTasksByTitle(String searchQuery) async {
    try {
      log('🔵 Searching tasks with query: "$searchQuery"');

      final response = await _supabase
          .from('tasks')
          .select()
          .ilike('title', '%$searchQuery%')
          .order('created_at', ascending: false);

      final List<Task> tasks = [];

      for (final taskData in response) {
        final collaborators = await _getTaskCollaborators(taskData['id']);

        final task = Task.fromJson({
          ...taskData,
          'collaborators': collaborators,
        });

        tasks.add(task);
      }

      log('✅ Found ${tasks.length} tasks matching "$searchQuery"');
      return tasks;
    } catch (e) {
      log('❌ Failed to search tasks: $e');
      rethrow;
    }
  }

  /// Helper method to get collaborators for a task
  Future<List<String>> _getTaskCollaborators(int taskId) async {
    try {
      final response = await _supabase
          .from('task_collaborators')
          .select('user_id')
          .eq('task_id', taskId);

      return response.map((item) => item['user_id'] as String).toList();
    } catch (e) {
      log('❌ Failed to get task collaborators: $e');
      return [];
    }
  }

  /// Helper method to add collaborators to a task
  Future<void> _addCollaborators(
      int taskId, List<String> collaboratorIds) async {
    try {
      final collaboratorData = collaboratorIds
          .map((userId) => {
                'task_id': taskId,
                'user_id': userId,
              })
          .toList();

      await _supabase.from('task_collaborators').insert(collaboratorData);

      log('✅ Added ${collaboratorIds.length} collaborators to task: $taskId');
    } catch (e) {
      log('❌ Failed to add collaborators: $e');
      rethrow;
    }
  }

  /// Helper method to update collaborators for a task
  Future<void> _updateTaskCollaborators(
      int taskId, List<String> collaboratorIds) async {
    try {
      // First remove existing collaborators
      await _supabase.from('task_collaborators').delete().eq('task_id', taskId);

      // Then add new collaborators
      if (collaboratorIds.isNotEmpty) {
        await _addCollaborators(taskId, collaboratorIds);
      }

      log('✅ Updated collaborators for task: $taskId');
    } catch (e) {
      log('❌ Failed to update task collaborators: $e');
      rethrow;
    }
  }
}
