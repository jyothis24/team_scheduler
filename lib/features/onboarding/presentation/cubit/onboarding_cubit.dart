import 'dart:io';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/onboarding_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository) : super(const OnboardingInitial()) {
    log('🏗️ OnboardingCubit initialized');
  }

  final OnboardingRepository _repository;
  final ImagePicker _picker = ImagePicker();

  // Internal state for user input
  String _name = '';
  File? _profileImage;

  void updateName(String name) {
    log('📝 Name updated: "$name"');
    _name = name;
    // Don't emit new state, just update internal variable
  }

  Future<void> pickImage() async {
    try {
      log('📸 Starting image picker');
      emit(const OnboardingLoading());
      log('🔄 State changed to: OnboardingLoading');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        _profileImage = File(image.path);
        log('✅ Image selected: ${image.path}');
        log('📁 File size: ${(await _profileImage!.length() / 1024).toStringAsFixed(2)} KB');
      } else {
        log('❌ Image selection cancelled by user');
      }

      // Always go back to loaded state after image picker
      emit(const OnboardingInitial());
      log('🔄 State changed to: OnboardingInitial');
    } catch (e) {
      log('❌ Image picker failed: $e');
      emit(OnboardingError(message: 'Error picking image: $e'));
      log('🔄 State changed to: OnboardingError');
    }
  }

  Future<void> validateAndContinue() async {
    log('🚀 Starting validation and continue process');
    log('📝 Current name: "$_name"');

    if (_name.trim().isEmpty) {
      log('❌ Validation failed: Name is empty');
      emit(const OnboardingValidationError(
        message: 'Please enter your name',
      ));
      log('🔄 State changed to: OnboardingValidationError (name)');
      return;
    }

    try {
      log('✅ Validation passed, starting API calls');
      emit(const OnboardingLoading());
      log('🔄 State changed to: OnboardingLoading');

      log('👤 Creating user profile...');
      // Create user profile
      final createdUser = await _repository.createUser(
        name: _name.trim(),
      );
      log('✅ Successfully created user with ID: ${createdUser['id']}');

      log('👤 Created User Details:');
      log('   ID: ${createdUser['id']}');
      log('   Name: ${createdUser['name']}');
      log('   Created At: ${createdUser['created_at']}');

      emit(OnboardingComplete(
        name: _name.trim(),
        profileImage: _profileImage,
        userId: createdUser['id'],
      ));
      log('🔄 State changed to: OnboardingComplete');
      log('🎉 Onboarding process completed successfully!');
    } catch (e) {
      log('❌ Onboarding process failed: $e');
      log('🔍 Error type: ${e.runtimeType}');
      emit(OnboardingError(message: 'Failed to complete onboarding: $e'));
      log('🔄 State changed to: OnboardingError');
    }
  }

  /// Fetches a specific user by ID
  Future<void> fetchUserById(String userId) async {
    try {
      log('👤 Fetching user with ID: $userId');
      emit(const OnboardingLoading());

      final user = await _repository.getUserById(userId);
      if (user != null) {
        log('✅ User found:');
        log('   ID: ${user['id']}');
        log('   Name: ${user['name']}');
        log('   Created At: ${user['created_at']}');
      } else {
        log('❌ User not found with ID: $userId');
      }

      emit(const OnboardingInitial());
    } catch (e) {
      log('❌ Failed to fetch user: $e');
      emit(OnboardingError(message: 'Failed to fetch user: $e'));
    }
  }

  void clearError() {
    log('🔄 Clearing error, returning to initial state');
    emit(const OnboardingInitial());
    log('🔄 State changed to: OnboardingInitial');
  }

  // Getters to access current values
  String get currentName {
    log('📖 Getting current name: "$_name"');
    return _name;
  }

  File? get currentProfileImage {
    log('📖 Getting current profile image: ${_profileImage != null ? "Available" : "Not available"}');
    return _profileImage;
  }
}
