import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../repositories/onboarding_repository.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../../../tasks/presentation/pages/task_list_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _nameController = TextEditingController();
  OnboardingCubit? _cubit;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final repository = OnboardingRepository();
        _cubit = OnboardingCubit(repository);
        return _cubit!;
      },
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          log("current onboarding state $state");
          if (state is OnboardingValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is OnboardingComplete) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${state.name}!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to Task List Page
            log('🚀 Navigating to TaskListPage with userId: ${state.userId}');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TaskListPage(userId: state.userId),
              ),
            );
          } else if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          log("current onboarding state $state");
          final cubit = context.read<OnboardingCubit>();
          final theme = Theme.of(context);

          return Scaffold(
            body: () {
              if (state is OnboardingInitial) {
                return _buildOnboardingContent(
                  context,
                  theme,
                  cubit,
                );
              } else if (state is OnboardingLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is OnboardingValidationError) {
                // Show the form with error state
                return _buildOnboardingContent(
                  context,
                  theme,
                  cubit,
                );
              } else if (state is OnboardingComplete) {
                return _buildOnboardingContent(
                  context,
                  theme,
                  cubit,
                );
              } else if (state is OnboardingError) {
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
              return const Center(child: CircularProgressIndicator());
            }(),
          );
        },
      ),
    );
  }

  Widget _buildOnboardingContent(
    BuildContext context,
    ThemeData theme,
    OnboardingCubit cubit,
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
              const Spacer(flex: 2),

              // Welcome Text
              Text(
                'Welcome to\nTeam Scheduler',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Let\'s get you set up',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),

              const Spacer(flex: 3),

              // Photo Upload Section
              Center(
                child: GestureDetector(
                  onTap: () => cubit.pickImage(),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      color: cubit.currentProfileImage != null
                          ? Colors.transparent
                          : theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    child: cubit.currentProfileImage != null
                        ? ClipOval(
                            child: Image.file(
                              cubit.currentProfileImage!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Name Input Field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController..text = cubit.currentName,
                  onChanged: (value) => cubit.updateName(value),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: GoogleFonts.poppins(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => cubit.validateAndContinue(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
