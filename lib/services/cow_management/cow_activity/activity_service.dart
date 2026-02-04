import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:logger/logger.dart';

final activityServiceProvider = Provider((ref) => ActivityService());

final activitiesProvider =
    FutureProvider.family<List<Activity>, int>((ref, cowId) async {
  // Optimization: Keep the provider alive for 5 minutes to cache the data.
  // This prevents reloading when switching tabs back and forth quickly.
  final link = ref.keepAlive();
  // Cancel the link if the provider is not listened to for 5 minutes
  final timer = Timer(const Duration(minutes: 5), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  final activityService = ref.watch(activityServiceProvider);
  return activityService.getActivitiesForCow(cowId);
});

class ActivityService {
  final _supabaseClient = supabase;

  // The table name in your Supabase database
  static const String _tableName = 'activities';

  /// Adds a new activity to the database.
  Future<void> addActivity(Activity activity) async {
    try {
      // 1. Insert the activity record
      final map = activity.toMapForInsert();
      await _supabaseClient.from(_tableName).insert(map);

      // 2. If it's a BIRTH activity, automatically create the new calf
      if (activity.activityType == ActivityType.BIRTH) {
        await _createCalfFromActivity(activity);
      }
    } catch (e) {
      Logger().e('Error adding activity: $e');
      throw Exception('Could not save activity: $e');
    }
  }

  Future<void> _createCalfFromActivity(Activity activity) async {
    try {
      // 1. Get Mother's (Dam) details to inherit Farm ID and User ID
      final damResponse = await _supabaseClient
          .from('animals')
          .select('farm_id, user_id')
          .eq('animal_id', activity.animalId)
          .single();

      final farmId = damResponse['farm_id'];
      final userId = damResponse['user_id'];

      // 2. Extract Calf Data from Activity
      final data = activity.data;
      final nidNumber = data['nid_number'] ?? '';
      final name = data['animal_name'] ?? 'ลูกโค (ไม่ระบุชื่อ)';
      final sex = data['sex'] ?? 'FEMALE';
      final breed = data['breed'] ?? 'ไม่ระบุ';
      final birthWeight = data['birth_weight'];

      // 3. Create New Cow Record
      final newCalf = {
        'nid_number': nidNumber,
        'animal_name': name,
        'sex': sex,
        'breed': breed,
        'weight': birthWeight, // Initial weight
        'birth_date': activity.activityDate.toIso8601String(),
        'dam_id': activity.animalId, // Link to Mother
        'farm_id': farmId,
        'user_id': userId,
        'status': 'ACTIVE', // Default status
        'is_deleted': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabaseClient.from('animals').insert(newCalf);
      Logger().i('Auto-created calf: $name (NID: $nidNumber)');
    } catch (e) {
      Logger().e('Error creating calf from birth activity: $e');
      // We don't throw here to avoid failing the "Activity Save" if the calf creation fails.
      // But we log it. User might need to check if calf exists.
      // Ideally, specific error handling/user notification would be better.
    }
  }

  /// Fetches all activities for a specific cow.
  Future<List<Activity>> getActivitiesForCow(int cowId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('animal_id', cowId)
          .order('activity_date', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final activities =
          response.map((item) => Activity.fromMap(item)).toList();
      return activities;
    } catch (e) {
      throw Exception('Could not fetch activities.');
    }
  }
}
