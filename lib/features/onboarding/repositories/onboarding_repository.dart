import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  final _supabase = Supabase.instance.client;

  /// Creates a new user in the database
  Future<Map<String, dynamic>> createUser({
    required String name,
  }) async {
    try {
      log('🔵 Creating new user with name: "$name"');

      final response = await _supabase
          .from('users')
          .insert({
            'name': name.trim(),
          })
          .select()
          .single();

      log('✅ User created successfully with ID: ${response['id']}');
      return response;
    } catch (e) {
      log('❌ Failed to create user: $e');
      rethrow;
    }
  }

  /// Fetches a specific user by their ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      log('🔵 Fetching user with ID: $userId');

      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response != null) {
        log('✅ User found with ID: $userId');
      } else {
        log('⚠️ No user found with ID: $userId');
      }

      return response;
    } catch (e) {
      log('❌ Failed to fetch user by ID: $e');
      rethrow;
    }
  }

  /// Updates a user's information
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? name,
  }) async {
    try {
      log('🔵 Updating user with ID: $userId');

      final Map<String, dynamic> updates = {};

      // Add name to updates if provided
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
        log('📝 Updating name to: "$name"');
      }

      // Perform the update if there are changes
      if (updates.isEmpty) {
        log('⚠️ No updates to perform');
        final currentUser = await getUserById(userId);
        return currentUser ?? {};
      }

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      log('✅ User updated successfully');
      return response;
    } catch (e) {
      log('❌ Failed to update user: $e');
      rethrow;
    }
  }

  /// Deletes a user from the database
  Future<void> deleteUser(String userId) async {
    try {
      log('🔵 Deleting user with ID: $userId');

      await _supabase.from('users').delete().eq('id', userId);

      log('✅ User deleted successfully');
    } catch (e) {
      log('❌ Failed to delete user: $e');
      rethrow;
    }
  }

  /// Searches users by name (case-insensitive partial match)
  Future<List<Map<String, dynamic>>> searchUsersByName(
      String searchQuery) async {
    try {
      log('🔵 Searching users with query: "$searchQuery"');

      final response = await _supabase
          .from('users')
          .select()
          .ilike('name', '%$searchQuery%')
          .order('created_at', ascending: false);

      log('✅ Found ${response.length} users matching "$searchQuery"');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('❌ Failed to search users: $e');
      rethrow;
    }
  }
}
