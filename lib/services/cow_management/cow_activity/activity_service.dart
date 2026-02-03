import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/supabase_config.dart';

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
      final map = activity.toMapForInsert();
      await _supabaseClient.from(_tableName).insert(map);
    } catch (e) {
      // You can add more robust error handling here.
      // For example, log the error or rethrow a more specific exception.
      throw Exception('Could not save activity. Please try again.');
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
