import '../../domain/models/task.dart';

enum TaskCreationStep { titleDescription, collaborators, duration, slot }

class TaskCreationData {
  final String title;
  final String? description;
  final List<String> selectedCollaborators;
  final int durationMinutes;
  final DateTime? selectedStartTime;
  final DateTime? selectedEndTime;

  const TaskCreationData({
    this.title = '',
    this.description,
    this.selectedCollaborators = const [],
    this.durationMinutes = 30,
    this.selectedStartTime,
    this.selectedEndTime,
  });

  TaskCreationData copyWith({
    String? title,
    String? description,
    List<String>? selectedCollaborators,
    int? durationMinutes,
    DateTime? selectedStartTime,
    DateTime? selectedEndTime,
  }) {
    return TaskCreationData(
      title: title ?? this.title,
      description: description ?? this.description,
      selectedCollaborators:
          selectedCollaborators ?? this.selectedCollaborators,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      selectedStartTime: selectedStartTime ?? this.selectedStartTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
    );
  }

  bool get isValid {
    return title.trim().isNotEmpty &&
        selectedCollaborators.isNotEmpty &&
        selectedStartTime != null &&
        selectedEndTime != null;
  }
}

abstract class TaskCreationState {
  const TaskCreationState();
}

class TaskCreationInitial extends TaskCreationState {
  const TaskCreationInitial();
}

class TaskCreationLoading extends TaskCreationState {
  const TaskCreationLoading();
}

class TaskCreationStepState extends TaskCreationState {
  final TaskCreationStep currentStep;
  final TaskCreationData data;
  final List<Map<String, dynamic>> availableUsers;
  final List<Map<String, dynamic>> availableSlots;

  const TaskCreationStepState({
    required this.currentStep,
    required this.data,
    required this.availableUsers,
    required this.availableSlots,
  });

  TaskCreationStepState copyWith({
    TaskCreationStep? currentStep,
    TaskCreationData? data,
    List<Map<String, dynamic>>? availableUsers,
    List<Map<String, dynamic>>? availableSlots,
  }) {
    return TaskCreationStepState(
      currentStep: currentStep ?? this.currentStep,
      data: data ?? this.data,
      availableUsers: availableUsers ?? this.availableUsers,
      availableSlots: availableSlots ?? this.availableSlots,
    );
  }
}

class TaskCreationSuccess extends TaskCreationState {
  final Task task;

  const TaskCreationSuccess({required this.task});
}

class TaskCreationError extends TaskCreationState {
  final String message;

  const TaskCreationError({required this.message});
}
