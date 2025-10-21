import '../../domain/models/availability.dart';

abstract class AvailabilityState {
  const AvailabilityState();
}

class AvailabilityInitial extends AvailabilityState {
  const AvailabilityInitial();
}

class AvailabilityLoading extends AvailabilityState {
  const AvailabilityLoading();
}

class AvailabilityLoaded extends AvailabilityState {
  final List<Availability> availabilitySlots;
  final String? currentUserId;

  const AvailabilityLoaded({
    required this.availabilitySlots,
    this.currentUserId,
  });

  AvailabilityLoaded copyWith({
    List<Availability>? availabilitySlots,
    String? currentUserId,
  }) {
    return AvailabilityLoaded(
      availabilitySlots: availabilitySlots ?? this.availabilitySlots,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class AvailabilityError extends AvailabilityState {
  final String message;

  const AvailabilityError({required this.message});
}
