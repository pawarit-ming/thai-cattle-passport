import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';
import 'package:th_cow_passport/supabase_config.dart';

final activityServiceProvider = Provider((ref) => ActivityService());

final activitiesProvider =
    FutureProvider.family<List<Activity>, int>((ref, cowId) async {
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
      print('Error saving activity: $e');
      throw Exception('Could not save activity. Please try again.');
    }
  }

  /// Fetches all activities for a specific cow.
  Future<List<Activity>> getActivitiesForCow(int cowId) async {
    try {
      print('[ActivityService] Fetching activities for cowId: $cowId');
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('animal_id', cowId)
          .order('activity_date', ascending: false);

      print('[ActivityService] Response from Supabase: $response');

      if (response.isEmpty) {
        print('[ActivityService] No activities found for cowId: $cowId');
        return [];
      }
      
      final activities = response.map((item) => Activity.fromMap(item)).toList();
      print('[ActivityService] Parsed ${activities.length} activities.');
      return activities;
    } catch (e) {
      print('[ActivityService] Error fetching activities for cowId $cowId: $e');
      throw Exception('Could not fetch activities.');
    }
  }
}
