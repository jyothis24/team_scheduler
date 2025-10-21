import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/task_creation_cubit.dart';
import '../cubit/task_creation_state.dart';
import '../../data/repositories/task_repository.dart';
import '../../../onboarding/repositories/onboarding_repository.dart';
import '../../../availability/data/repositories/availability_repository.dart';

class TaskCreationPage extends StatefulWidget {
  final String userId;

  const TaskCreationPage({
    super.key,
    required this.userId,
  });

  @override
  State<TaskCreationPage> createState() => _TaskCreationPageState();
}

class _TaskCreationPageState extends State<TaskCreationPage> {
  TaskCreationCubit? _cubit;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('🏗️ TaskCreationPage building with userId: ${widget.userId}');
    return BlocProvider(
      create: (_) {
        final taskRepository = TaskRepository();
        final onboardingRepository = OnboardingRepository();
        final availabilityRepository = AvailabilityRepository();
        log('🔧 Creating TaskCreationCubit with userId: ${widget.userId}');
        _cubit = TaskCreationCubit(
          taskRepository,
          onboardingRepository,
          availabilityRepository,
          widget.userId,
        );
        return _cubit!;
      },
      child: BlocConsumer<TaskCreationCubit, TaskCreationState>(
        listener: (context, state) {
          log("current task creation state $state");
          if (state is TaskCreationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TaskCreationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Task "${state.task.title}" created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          log("current task creation state $state");
          final cubit = context.read<TaskCreationCubit>();
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Create Task',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Container(
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
                child: () {
                  if (state is TaskCreationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaskCreationStepState) {
                    return _buildStepContent(context, theme, cubit, state);
                  } else if (state is TaskCreationError) {
                    return _buildErrorContent(context, theme, cubit, state);
                  }
                  return const Center(child: CircularProgressIndicator());
                }(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(theme, state.currentStep),

        const SizedBox(height: 24),

        // Step content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildStepWidget(context, theme, cubit, state),
          ),
        ),

        // Navigation buttons
        _buildNavigationButtons(context, theme, cubit, state),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProgressIndicator(
      ThemeData theme, TaskCreationStep currentStep) {
    final steps = TaskCreationStep.values;
    final currentIndex = steps.indexOf(currentStep);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final isActive = index <= currentIndex;
          final isCompleted = index < currentIndex;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isActive ? theme.colorScheme.primary : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepWidget(
    BuildContext context,
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    switch (state.currentStep) {
      case TaskCreationStep.titleDescription:
        return _buildTitleDescriptionStep(theme, cubit, state);
      case TaskCreationStep.collaborators:
        return _buildCollaboratorsStep(theme, cubit, state);
      case TaskCreationStep.duration:
        return _buildDurationStep(theme, cubit, state);
      case TaskCreationStep.slot:
        return _buildSlotStep(theme, cubit, state);
    }
  }

  Widget _buildTitleDescriptionStep(
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Task Title + Description',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Title field
        TextField(
          controller: _titleController..text = state.data.title,
          onChanged: (value) => cubit.updateTitle(value),
          style: GoogleFonts.poppins(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Task Title',
            hintText: 'Enter task title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),

        // Description field
        TextField(
          controller: _descriptionController
            ..text = state.data.description ?? '',
          onChanged: (value) => cubit.updateDescription(value),
          style: GoogleFonts.poppins(fontSize: 16),
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Enter task description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon:
                Icon(Icons.description, color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCollaboratorsStep(
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Choose Collaborators',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: state.availableUsers.length,
            itemBuilder: (context, index) {
              final user = state.availableUsers[index];
              final userId = user['id'] as String;
              final userName = user['name'] as String;
              final isSelected =
                  state.data.selectedCollaborators.contains(userId);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  title: Text(
                    userName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'ID: $userId',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  value: isSelected,
                  onChanged: (value) => cubit.toggleCollaborator(userId),
                  activeColor: theme.colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationStep(
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    final durations = [10, 15, 30, 60];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Choose Duration',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: durations.length,
            itemBuilder: (context, index) {
              final duration = durations[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<int>(
                  title: Text(
                    '$duration minutes',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _getDurationDescription(duration),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  value: duration,
                  groupValue: state.data.durationMinutes,
                  onChanged: (value) {
                    if (value != null) {
                      cubit.updateDuration(value);
                    }
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlotStep(
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Choose Available Slot',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: state.availableSlots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No available slots found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please ensure collaborators have availability slots',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = state.availableSlots[index];
                    final startTime = slot['start_time'] as DateTime;
                    final endTime = slot['end_time'] as DateTime;
                    final availableUsers =
                        slot['available_users'] as List<String>;
                    final duration = slot['duration_minutes'] as int;

                    final isSelected =
                        state.data.selectedStartTime == startTime &&
                            state.data.selectedEndTime == endTime;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<Map<String, dynamic>>(
                        title: Text(
                          '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration: $duration minutes',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Available: ${availableUsers.join(', ')}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        value: slot,
                        groupValue: isSelected ? slot : null,
                        onChanged: (value) {
                          if (value != null) {
                            cubit.selectSlot(startTime, endTime);
                          }
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationStepState state,
  ) {
    final isFirstStep = state.currentStep == TaskCreationStep.titleDescription;
    final isLastStep = state.currentStep == TaskCreationStep.slot;
    final canProceed = _canProceedToNextStep(state);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: ElevatedButton(
                onPressed: () => cubit.previousStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: canProceed
                  ? (isLastStep
                      ? () => cubit.createTask()
                      : () => cubit.nextStep())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLastStep ? 'Create Task' : 'Next',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep(TaskCreationStepState state) {
    switch (state.currentStep) {
      case TaskCreationStep.titleDescription:
        return state.data.title.trim().isNotEmpty;
      case TaskCreationStep.collaborators:
        return state.data.selectedCollaborators.isNotEmpty;
      case TaskCreationStep.duration:
        return true; // Duration is always selected (default 30)
      case TaskCreationStep.slot:
        return state.data.selectedStartTime != null &&
            state.data.selectedEndTime != null;
    }
  }

  Widget _buildErrorContent(
    BuildContext context,
    ThemeData theme,
    TaskCreationCubit cubit,
    TaskCreationError state,
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

  String _getDurationDescription(int duration) {
    switch (duration) {
      case 10:
        return 'Quick check-in';
      case 15:
        return 'Brief meeting';
      case 30:
        return 'Standard meeting';
      case 60:
        return 'Extended discussion';
      default:
        return 'Custom duration';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
