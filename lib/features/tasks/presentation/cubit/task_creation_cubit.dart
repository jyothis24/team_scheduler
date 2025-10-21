import 'dart:developer';
import 'package:bloc/bloc.dart';
import '../../data/repositories/task_repository.dart';
import '../../../onboarding/repositories/onboarding_repository.dart';
import '../../../availability/data/repositories/availability_repository.dart';
import 'task_creation_state.dart';

class TaskCreationCubit extends Cubit<TaskCreationState> {
  TaskCreationCubit(
    this._taskRepository,
    this._onboardingRepository,
    this._availabilityRepository,
    this._currentUserId,
  ) : super(const TaskCreationInitial()) {
    log('🏗️ TaskCreationCubit initialized with user: $_currentUserId');
    _initializeTaskCreation();
  }

  final TaskRepository _taskRepository;
  final OnboardingRepository _onboardingRepository;
  final AvailabilityRepository _availabilityRepository;
  final String _currentUserId;

  void _initializeTaskCreation() async {
    try {
      log('📋 Initializing task creation...');
      emit(const TaskCreationLoading());

      // Load available users only (slots will be calculated when collaborators are selected)
      final users = await _loadAvailableUsers();

      emit(TaskCreationStepState(
        currentStep: TaskCreationStep.titleDescription,
        data: const TaskCreationData(),
        availableUsers: users,
        availableSlots: [], // Empty initially, will be calculated when collaborators are selected
      ));
      log('✅ Task creation initialized');
    } catch (e) {
      log('❌ Failed to initialize task creation: $e');
      emit(
          TaskCreationError(message: 'Failed to initialize task creation: $e'));
    }
  }

  Future<List<Map<String, dynamic>>> _loadAvailableUsers() async {
    try {
      log('👥 Loading available users...');
      // For now, we'll get all users. In a real app, you might want to filter this
      final users = await _onboardingRepository.searchUsersByName('');
      log('✅ Loaded ${users.length} users');
      return users;
    } catch (e) {
      log('❌ Failed to load users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _calculateAvailableSlots(
      List<String> selectedCollaboratorIds) async {
    try {
      log('📅 Calculating available slots for ${selectedCollaboratorIds.length} collaborators...');

      if (selectedCollaboratorIds.isEmpty) {
        log('⚠️ No collaborators selected, returning empty slots');
        return [];
      }

      // Get availability only for selected collaborators
      final List<Map<String, dynamic>> allSlots = [];

      for (final collaboratorId in selectedCollaboratorIds) {
        log('🔵 Fetching availability for collaborator: $collaboratorId');
        final availability =
            await _availabilityRepository.getAvailabilityByUser(collaboratorId);

        // Get user name for display
        final user = await _onboardingRepository.getUserById(collaboratorId);
        final userName = user?['name'] ?? 'Unknown User';

        for (final slot in availability) {
          allSlots.add({
            'user_id': slot.userId,
            'start_time': slot.startTime,
            'end_time': slot.endTime,
            'user_name': userName,
          });
        }
        log('✅ Found ${availability.length} availability slots for collaborator: $collaboratorId');
      }

      // Calculate overlapping time slots
      final overlappingSlots = _findOverlappingSlots(allSlots);

      log('✅ Calculated ${overlappingSlots.length} available slots');
      return overlappingSlots;
    } catch (e) {
      log('❌ Failed to calculate slots: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _findOverlappingSlots(
      List<Map<String, dynamic>> allSlots) {
    if (allSlots.isEmpty) return [];

    // Sort slots by start time
    allSlots.sort((a, b) =>
        (a['start_time'] as DateTime).compareTo(b['start_time'] as DateTime));

    List<Map<String, dynamic>> overlappingSlots = [];

    // Find time ranges where multiple users are available
    for (int i = 0; i < allSlots.length; i++) {
      final currentSlot = allSlots[i];
      final currentStart = currentSlot['start_time'] as DateTime;
      final currentEnd = currentSlot['end_time'] as DateTime;

      List<String> availableUsers = [currentSlot['user_name'] as String];

      // Check for overlaps with other slots
      for (int j = i + 1; j < allSlots.length; j++) {
        final otherSlot = allSlots[j];
        final otherStart = otherSlot['start_time'] as DateTime;
        final otherEnd = otherSlot['end_time'] as DateTime;

        // Check if slots overlap
        if (currentStart.isBefore(otherEnd) && currentEnd.isAfter(otherStart)) {
          final overlapStart =
              currentStart.isAfter(otherStart) ? currentStart : otherStart;
          final overlapEnd =
              currentEnd.isBefore(otherEnd) ? currentEnd : otherEnd;

          if (overlapStart.isBefore(overlapEnd)) {
            availableUsers.add(otherSlot['user_name'] as String);

            overlappingSlots.add({
              'start_time': overlapStart,
              'end_time': overlapEnd,
              'available_users': availableUsers.toSet().toList(),
              'duration_minutes': overlapEnd.difference(overlapStart).inMinutes,
            });
          }
        }
      }
    }

    // Remove duplicates and sort by start time
    overlappingSlots = overlappingSlots.toSet().toList();
    overlappingSlots.sort((a, b) =>
        (a['start_time'] as DateTime).compareTo(b['start_time'] as DateTime));

    return overlappingSlots;
  }

  void updateTitle(String title) {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      emit(currentState.copyWith(
        data: currentState.data.copyWith(title: title),
      ));
    }
  }

  void updateDescription(String description) {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      emit(currentState.copyWith(
        data: currentState.data.copyWith(description: description),
      ));
    }
  }

  void toggleCollaborator(String userId) async {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      final currentCollaborators =
          List<String>.from(currentState.data.selectedCollaborators);

      if (currentCollaborators.contains(userId)) {
        currentCollaborators.remove(userId);
      } else {
        currentCollaborators.add(userId);
      }

      // Recalculate available slots with new collaborators
      final newSlots = await _calculateAvailableSlots(currentCollaborators);

      emit(currentState.copyWith(
        data: currentState.data
            .copyWith(selectedCollaborators: currentCollaborators),
        availableSlots: newSlots,
      ));
    }
  }

  void updateDuration(int durationMinutes) {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      emit(currentState.copyWith(
        data: currentState.data.copyWith(durationMinutes: durationMinutes),
      ));
    }
  }

  void selectSlot(DateTime startTime, DateTime endTime) {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      emit(currentState.copyWith(
        data: currentState.data.copyWith(
          selectedStartTime: startTime,
          selectedEndTime: endTime,
        ),
      ));
    }
  }

  void nextStep() async {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      final nextStep = _getNextStep(currentState.currentStep);

      // If moving to slot step, recalculate slots for selected collaborators
      if (nextStep == TaskCreationStep.slot &&
          currentState.data.selectedCollaborators.isNotEmpty) {
        log('🔄 Moving to slot step, recalculating slots...');
        final newSlots = await _calculateAvailableSlots(
            currentState.data.selectedCollaborators);
        emit(currentState.copyWith(
          currentStep: nextStep,
          availableSlots: newSlots,
        ));
      } else {
        emit(currentState.copyWith(currentStep: nextStep));
      }

      log('🔄 Moved to step: $nextStep');
    }
  }

  void previousStep() {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;
      final previousStep = _getPreviousStep(currentState.currentStep);

      emit(currentState.copyWith(currentStep: previousStep));
      log('🔄 Moved to step: $previousStep');
    }
  }

  TaskCreationStep _getNextStep(TaskCreationStep currentStep) {
    switch (currentStep) {
      case TaskCreationStep.titleDescription:
        return TaskCreationStep.collaborators;
      case TaskCreationStep.collaborators:
        return TaskCreationStep.duration;
      case TaskCreationStep.duration:
        return TaskCreationStep.slot;
      case TaskCreationStep.slot:
        return TaskCreationStep.slot; // Last step
    }
  }

  TaskCreationStep _getPreviousStep(TaskCreationStep currentStep) {
    switch (currentStep) {
      case TaskCreationStep.titleDescription:
        return TaskCreationStep.titleDescription; // First step
      case TaskCreationStep.collaborators:
        return TaskCreationStep.titleDescription;
      case TaskCreationStep.duration:
        return TaskCreationStep.collaborators;
      case TaskCreationStep.slot:
        return TaskCreationStep.duration;
    }
  }

  Future<void> createTask() async {
    if (state is TaskCreationStepState) {
      final currentState = state as TaskCreationStepState;

      if (!currentState.data.isValid) {
        emit(const TaskCreationError(
            message: 'Please fill in all required fields'));
        return;
      }

      try {
        log('➕ Creating task: "${currentState.data.title}"');
        emit(const TaskCreationLoading());

        final task = await _taskRepository.createTask(
          title: currentState.data.title,
          description: currentState.data.description,
          createdBy: _currentUserId,
          startTime: currentState.data.selectedStartTime,
          endTime: currentState.data.selectedEndTime,
          collaborators: currentState.data.selectedCollaborators,
        );

        log('✅ Task created successfully');
        emit(TaskCreationSuccess(task: task));
      } catch (e) {
        log('❌ Failed to create task: $e');
        emit(TaskCreationError(message: 'Failed to create task: $e'));
      }
    }
  }

  void clearError() {
    if (state is TaskCreationStepState) {
      // Stay in current step
      return;
    }
    emit(const TaskCreationInitial());
    _initializeTaskCreation();
  }
}
