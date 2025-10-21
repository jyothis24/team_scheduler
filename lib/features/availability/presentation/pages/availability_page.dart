import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/availability_cubit.dart';
import '../cubit/availability_state.dart';
import '../../domain/models/availability.dart';
import '../../data/repositories/availability_repository.dart';

class AvailabilityPage extends StatefulWidget {
  final String userId;

  const AvailabilityPage({
    super.key,
    required this.userId,
  });

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  AvailabilityCubit? _cubit;

  @override
  Widget build(BuildContext context) {
    log('🏗️ AvailabilityPage building with userId: ${widget.userId}');
    return BlocProvider(
      create: (_) {
        final availabilityRepository = AvailabilityRepository();
        log('🔧 Creating AvailabilityCubit with userId: ${widget.userId}');
        _cubit = AvailabilityCubit(availabilityRepository, widget.userId);
        return _cubit!;
      },
      child: BlocConsumer<AvailabilityCubit, AvailabilityState>(
        listener: (context, state) {
          log("current availability state $state");
          if (state is AvailabilityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          log("current availability state $state");
          final cubit = context.read<AvailabilityCubit>();
          final theme = Theme.of(context);

          return Scaffold(
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
                child: Column(
                  children: [
                    _buildHeader(theme, cubit),
                    const SizedBox(height: 16),
                    _buildActionButtons(theme, cubit),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildAvailabilityList(theme, state, cubit),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AvailabilityCubit cubit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Availability',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: () => cubit.refreshAvailability(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AvailabilityCubit cubit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddSlotDialog(context, cubit),
              icon: const Icon(Icons.add),
              label: const Text('Add New Slot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Task List'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityList(
      ThemeData theme, AvailabilityState state, AvailabilityCubit cubit) {
    if (state is AvailabilityLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is AvailabilityLoaded) {
      if (state.availabilitySlots.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No availability slots found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first availability slot to get started',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: state.availabilitySlots.length,
        itemBuilder: (context, index) {
          final availability = state.availabilitySlots[index];
          return AvailabilityCard(
            availability: availability,
            theme: theme,
            onEdit: () => _showEditSlotDialog(context, cubit, availability),
            onDelete: () =>
                _showDeleteConfirmation(context, cubit, availability),
          );
        },
      );
    } else if (state is AvailabilityError) {
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
    return const SizedBox.shrink();
  }

  void _showAddSlotDialog(BuildContext context, AvailabilityCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AddSlotDialog(
        onSave: (startTime, endTime) {
          cubit.createAvailability(
            startTime: startTime,
            endTime: endTime,
          );
        },
      ),
    );
  }

  void _showEditSlotDialog(BuildContext context, AvailabilityCubit cubit,
      Availability availability) {
    showDialog(
      context: context,
      builder: (context) => EditSlotDialog(
        availability: availability,
        onSave: (startTime, endTime) {
          cubit.updateAvailability(
            availabilityId: availability.id,
            startTime: startTime,
            endTime: endTime,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AvailabilityCubit cubit,
      Availability availability) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Availability Slot'),
        content: Text(
            'Are you sure you want to delete the slot "${availability.formattedSlot}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              cubit.deleteAvailability(availability.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AvailabilityCard extends StatelessWidget {
  final Availability availability;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AvailabilityCard({
    super.key,
    required this.availability,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slot ${availability.id}: ${availability.formattedSlot}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${availability.durationMinutes} minutes',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddSlotDialog extends StatefulWidget {
  final Function(DateTime startTime, DateTime endTime) onSave;

  const AddSlotDialog({super.key, required this.onSave});

  @override
  State<AddSlotDialog> createState() => _AddSlotDialogState();
}

class _AddSlotDialogState extends State<AddSlotDialog> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Availability Slot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Start Time'),
            subtitle: Text(_startTime?.format(context) ?? 'Select start time'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                });
              }
            },
          ),
          ListTile(
            title: Text('End Time'),
            subtitle: Text(_endTime?.format(context) ?? 'Select end time'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _startTime != null && _endTime != null
              ? () {
                  final now = DateTime.now();
                  final startDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    _startTime!.hour,
                    _startTime!.minute,
                  );
                  final endDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    _endTime!.hour,
                    _endTime!.minute,
                  );
                  widget.onSave(startDateTime, endDateTime);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class EditSlotDialog extends StatefulWidget {
  final Availability availability;
  final Function(DateTime startTime, DateTime endTime) onSave;

  const EditSlotDialog({
    super.key,
    required this.availability,
    required this.onSave,
  });

  @override
  State<EditSlotDialog> createState() => _EditSlotDialogState();
}

class _EditSlotDialogState extends State<EditSlotDialog> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.fromDateTime(widget.availability.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.availability.endTime);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Availability Slot'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Start Time'),
            subtitle: Text(_startTime?.format(context) ?? 'Select start time'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime ?? TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                });
              }
            },
          ),
          ListTile(
            title: Text('End Time'),
            subtitle: Text(_endTime?.format(context) ?? 'Select end time'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime ?? TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _startTime != null && _endTime != null
              ? () {
                  final now = DateTime.now();
                  final startDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    _startTime!.hour,
                    _startTime!.minute,
                  );
                  final endDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    _endTime!.hour,
                    _endTime!.minute,
                  );
                  widget.onSave(startDateTime, endDateTime);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
