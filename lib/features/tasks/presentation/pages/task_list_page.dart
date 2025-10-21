import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/task_list_cubit.dart';
import '../cubit/task_list_state.dart';
import '../../domain/models/task.dart';
import '../../data/repositories/task_repository.dart';

class TaskListPage extends StatefulWidget {
  final String userId;

  const TaskListPage({
    super.key,
    required this.userId,
  });

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  TaskListCubit? _cubit;

  @override
  Widget build(BuildContext context) {
    log('🏗️ TaskListPage building with userId: ${widget.userId}');
    return BlocProvider(
      create: (_) {
        final taskRepository = TaskRepository();
        log('🔧 Creating TaskListCubit with userId: ${widget.userId}');
        _cubit = TaskListCubit(taskRepository, widget.userId);
        return _cubit!;
      },
      child: BlocConsumer<TaskListCubit, TaskListState>(
        listener: (context, state) {
          log("current task list state $state");
          if (state is TaskListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          log("current task list state $state");
          final cubit = context.read<TaskListCubit>();
          final theme = Theme.of(context);

          return Scaffold(
            body: () {
              if (state is TaskListInitial || state is TaskListLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is TaskListLoaded) {
                return _buildTaskListContent(context, theme, cubit, state);
              } else if (state is TaskListError) {
                return _buildErrorContent(context, theme, cubit, state);
              }
              return const Center(child: CircularProgressIndicator());
            }(),
          );
        },
      ),
    );
  }

  Widget _buildTaskListContent(
    BuildContext context,
    ThemeData theme,
    TaskListCubit cubit,
    TaskListLoaded state,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Task List',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => cubit.refreshTasks(),
                    icon: Icon(
                      Icons.refresh,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => cubit.addTask(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => cubit.manageSlots(context),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Manage Slots'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['All', 'Created', 'Mine'].map((filter) {
                        final isSelected = state.selectedFilter == filter;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  cubit.changeFilter(filter);
                                }
                              },
                              selectedColor:
                                  theme.colorScheme.primary.withOpacity(0.2),
                              checkmarkColor: theme.colorScheme.primary,
                              labelStyle: GoogleFonts.poppins(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Task List
              Expanded(
                child: state.tasks.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        itemCount: state.tasks.length,
                        itemBuilder: (context, index) {
                          final task = state.tasks[index];
                          return _buildTaskCard(context, theme, task);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, ThemeData theme, Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title
          Text(
            'Task: ${task.title}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Duration
          Text(
            'Duration: ${task.durationMinutes} min',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),

          // Collaborators
          Text(
            'Collaborators: ${task.collaborators.join(', ')}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),

          // Slot
          if (task.slotStart != null && task.slotEnd != null)
            Text(
              'Slot: ${task.slotStart} - ${task.slotEnd}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'Slot: Not scheduled',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first task to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    ThemeData theme,
    TaskListCubit cubit,
    TaskListError state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => cubit.clearError(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
