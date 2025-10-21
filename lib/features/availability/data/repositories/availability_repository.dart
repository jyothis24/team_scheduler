import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/availability.dart';

class AvailabilityRepository {
  final _supabase = Supabase.instance.client;

  /// Creates a new availability slot in the database
  Future<Availability> createAvailability({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      log('🔵 Creating new availability slot for user: $userId');
      log('📅 Time slot: ${startTime.toIso8601String()} - ${endTime.toIso8601String()}');

      final availabilityData = {
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };

      final response = await _supabase
          .from('availability')
          .insert(availabilityData)
          .select()
          .single();

      log('✅ Availability slot created successfully with ID: ${response['id']}');
      return Availability.fromJson(response);
    } catch (e) {
      log('❌ Failed to create availability slot: $e');
      rethrow;
    }
  }

  /// Fetches all availability slots for a specific user
  Future<List<Availability>> getAvailabilityByUser(String userId) async {
    try {
      log('🔵 Fetching availability slots for user: $userId');

      final response = await _supabase
          .from('availability')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: true);

      final List<Availability> availabilitySlots =
          response.map((slot) => Availability.fromJson(slot)).toList();

      log('✅ Found ${availabilitySlots.length} availability slots for user: $userId');
      return availabilitySlots;
    } catch (e) {
      log('❌ Failed to fetch availability by user: $e');
      rethrow;
    }
  }

  /// Fetches a specific availability slot by ID
  Future<Availability?> getAvailabilityById(int availabilityId) async {
    try {
      log('🔵 Fetching availability slot with ID: $availabilityId');

      final response = await _supabase
          .from('availability')
          .select()
          .eq('id', availabilityId)
          .maybeSingle();

      if (response == null) {
        log('⚠️ No availability slot found with ID: $availabilityId');
        return null;
      }

      final availability = Availability.fromJson(response);
      log('✅ Availability slot found with ID: $availabilityId');
      return availability;
    } catch (e) {
      log('❌ Failed to fetch availability by ID: $e');
      rethrow;
    }
  }

  /// Updates an availability slot's information
  Future<Availability> updateAvailability({
    required int availabilityId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      log('🔵 Updating availability slot with ID: $availabilityId');

      final Map<String, dynamic> updates = {};

      // Add fields to updates if provided
      if (startTime != null) {
        updates['start_time'] = startTime.toIso8601String();
        log('📝 Updating start time');
      }

      if (endTime != null) {
        updates['end_time'] = endTime.toIso8601String();
        log('📝 Updating end time');
      }

      // Perform the update if there are changes
      if (updates.isNotEmpty) {
        await _supabase
            .from('availability')
            .update(updates)
            .eq('id', availabilityId);
        log('✅ Availability slot updated successfully');
      }

      // Return the updated availability slot
      final updatedAvailability = await getAvailabilityById(availabilityId);
      return updatedAvailability!;
    } catch (e) {
      log('❌ Failed to update availability slot: $e');
      rethrow;
    }
  }

  /// Deletes an availability slot from the database
  Future<void> deleteAvailability(int availabilityId) async {
    try {
      log('🔵 Deleting availability slot with ID: $availabilityId');

      await _supabase.from('availability').delete().eq('id', availabilityId);

      log('✅ Availability slot deleted successfully');
    } catch (e) {
      log('❌ Failed to delete availability slot: $e');
      rethrow;
    }
  }

  /// Gets all availability slots (for admin purposes)
  Future<List<Availability>> getAllAvailability() async {
    try {
      log('🔵 Fetching all availability slots...');

      final response = await _supabase
          .from('availability')
          .select()
          .order('created_at', ascending: false);

      final List<Availability> availabilitySlots =
          response.map((slot) => Availability.fromJson(slot)).toList();

      log('✅ Successfully fetched ${availabilitySlots.length} availability slots');
      return availabilitySlots;
    } catch (e) {
      log('❌ Failed to fetch all availability slots: $e');
      rethrow;
    }
  }

  /// Checks for overlapping availability slots for a user
  Future<bool> hasOverlappingSlot({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    int? excludeId, // Exclude this ID when checking (for updates)
  }) async {
    try {
      log('🔵 Checking for overlapping slots for user: $userId');

      var query = _supabase
          .from('availability')
          .select('id')
          .eq('user_id', userId)
          .or('and(start_time.lt.$endTime,end_time.gt.$startTime)');

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      final hasOverlap = response.isNotEmpty;

      log('${hasOverlap ? '⚠️' : '✅'} Overlap check result: $hasOverlap');
      return hasOverlap;
    } catch (e) {
      log('❌ Failed to check for overlapping slots: $e');
      rethrow;
    }
  }

  /// Gets availability slots for a specific date range
  Future<List<Availability>> getAvailabilityInRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      log('🔵 Fetching availability slots in range for user: $userId');
      log('📅 Range: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}');

      final response = await _supabase
          .from('availability')
          .select()
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time', ascending: true);

      final List<Availability> availabilitySlots =
          response.map((slot) => Availability.fromJson(slot)).toList();

      log('✅ Found ${availabilitySlots.length} availability slots in range');
      return availabilitySlots;
    } catch (e) {
      log('❌ Failed to fetch availability in range: $e');
      rethrow;
    }
  }
}
