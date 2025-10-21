import 'dart:developer';
import 'package:bloc/bloc.dart';
import '../../data/repositories/availability_repository.dart';
import 'availability_state.dart';

class AvailabilityCubit extends Cubit<AvailabilityState> {
  AvailabilityCubit(this._availabilityRepository, this._currentUserId)
      : super(const AvailabilityInitial()) {
    log('🏗️ AvailabilityCubit initialized with user: $_currentUserId');
    _loadAvailability();
  }

  final AvailabilityRepository _availabilityRepository;
  final String _currentUserId;

  void _loadAvailability() async {
    try {
      log('📋 Loading availability slots...');
      log('👤 Current user ID: $_currentUserId');
      emit(const AvailabilityLoading());

      final availabilitySlots =
          await _availabilityRepository.getAvailabilityByUser(_currentUserId);

      emit(AvailabilityLoaded(
        availabilitySlots: availabilitySlots,
        currentUserId: _currentUserId,
      ));
      log('✅ Availability slots loaded: ${availabilitySlots.length} slots');
    } catch (e) {
      log('❌ Failed to load availability slots: $e');
      emit(AvailabilityError(message: 'Failed to load availability slots: $e'));
    }
  }

  /// Creates a new availability slot
  Future<void> createAvailability({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      log('➕ Creating new availability slot');
      log('📅 Time slot: ${startTime.toIso8601String()} - ${endTime.toIso8601String()}');
      emit(const AvailabilityLoading());

      // Check for overlapping slots
      final hasOverlap = await _availabilityRepository.hasOverlappingSlot(
        userId: _currentUserId,
        startTime: startTime,
        endTime: endTime,
      );

      if (hasOverlap) {
        log('⚠️ Overlapping slot detected');
        emit(const AvailabilityError(
          message: 'This time slot overlaps with an existing availability slot',
        ));
        return;
      }

      await _availabilityRepository.createAvailability(
        userId: _currentUserId,
        startTime: startTime,
        endTime: endTime,
      );

      log('✅ Availability slot created successfully');
      _loadAvailability(); // Reload slots to show the new one
    } catch (e) {
      log('❌ Failed to create availability slot: $e');
      emit(
          AvailabilityError(message: 'Failed to create availability slot: $e'));
    }
  }

  /// Updates an existing availability slot
  Future<void> updateAvailability({
    required int availabilityId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      log('✏️ Updating availability slot: $availabilityId');
      emit(const AvailabilityLoading());

      // Check for overlapping slots (excluding current one)
      if (startTime != null || endTime != null) {
        final currentSlot =
            await _availabilityRepository.getAvailabilityById(availabilityId);
        if (currentSlot != null) {
          final checkStartTime = startTime ?? currentSlot.startTime;
          final checkEndTime = endTime ?? currentSlot.endTime;

          final hasOverlap = await _availabilityRepository.hasOverlappingSlot(
            userId: _currentUserId,
            startTime: checkStartTime,
            endTime: checkEndTime,
            excludeId: availabilityId,
          );

          if (hasOverlap) {
            log('⚠️ Overlapping slot detected');
            emit(const AvailabilityError(
              message:
                  'This time slot overlaps with an existing availability slot',
            ));
            return;
          }
        }
      }

      await _availabilityRepository.updateAvailability(
        availabilityId: availabilityId,
        startTime: startTime,
        endTime: endTime,
      );

      log('✅ Availability slot updated successfully');
      _loadAvailability(); // Reload slots to show the updated one
    } catch (e) {
      log('❌ Failed to update availability slot: $e');
      emit(
          AvailabilityError(message: 'Failed to update availability slot: $e'));
    }
  }

  /// Deletes an availability slot
  Future<void> deleteAvailability(int availabilityId) async {
    try {
      log('🗑️ Deleting availability slot: $availabilityId');
      emit(const AvailabilityLoading());

      await _availabilityRepository.deleteAvailability(availabilityId);

      log('✅ Availability slot deleted successfully');
      _loadAvailability(); // Reload slots to remove the deleted one
    } catch (e) {
      log('❌ Failed to delete availability slot: $e');
      emit(
          AvailabilityError(message: 'Failed to delete availability slot: $e'));
    }
  }

  void refreshAvailability() {
    log('🔄 Refreshing availability slots...');
    _loadAvailability();
  }

  void clearError() {
    log('🔄 Clearing error, returning to initial state');
    emit(const AvailabilityInitial());
    _loadAvailability();
  }

  void backToTaskList() {
    log('🔙 Back to Task List button pressed');
    // TODO: Navigate back to Task List page
  }
}
