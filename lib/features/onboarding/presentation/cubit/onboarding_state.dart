import 'dart:io';

abstract class OnboardingState {
  const OnboardingState();
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingValidationError extends OnboardingState {
  final String message;

  const OnboardingValidationError({required this.message});
}

class OnboardingComplete extends OnboardingState {
  final String name;
  final File? profileImage;
  final String userId;

  const OnboardingComplete({
    required this.name,
    this.profileImage,
    required this.userId,
  });
}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError({required this.message});
}
