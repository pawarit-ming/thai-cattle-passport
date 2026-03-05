import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/cow_management/models/vaccine_model.dart';
import 'package:th_cow_passport/supabase_config.dart';

final vaccineServiceProvider = Provider((ref) => VaccineService());

/// Provider ที่ดึงรายการวัคซีนจาก Supabase (cached 30 นาที)
final vaccinesProvider = FutureProvider<List<Vaccine>>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 30), () => link.close());
  ref.onDispose(() => timer.cancel());

  final service = ref.watch(vaccineServiceProvider);
  return service.fetchVaccines();
});

class VaccineService {
  final _logger = Logger();
  static const String _tableName = 'vaccines';

  /// ดึงรายการวัคซีนทั้งหมดที่ active
  Future<List<Vaccine>> fetchVaccines() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('id');

      return (response as List)
          .map((e) => Vaccine.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error fetching vaccines: $e');
      rethrow;
    }
  }

  /// ค้นหาวัคซีนจาก ID
  Future<Vaccine?> getVaccineById(String id) async {
    try {
      final response =
          await supabase.from(_tableName).select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return Vaccine.fromMap(response);
    } catch (e) {
      _logger.e('Error fetching vaccine $id: $e');
      return null;
    }
  }

  /// ดึงประวัติวัคซีนของวัวตัวนั้น
  /// Returns Map<vaccineId, List<{dose_number, activity_date}>>
  Future<Map<String, List<Map<String, dynamic>>>> fetchVaccineHistory(
      int cowId) async {
    try {
      final response = await supabase
          .from('activities')
          .select('data, activity_date')
          .eq('animal_id', cowId)
          .eq('activity_type', 'VACCINE')
          .order('activity_date', ascending: true);

      final Map<String, List<Map<String, dynamic>>> history = {};
      for (final row in response) {
        final data = row['data'] as Map<String, dynamic>?;
        if (data == null) continue;
        final vaccineId = data['vaccine_id'] as String?;
        final doseNumber = data['dose_number'];
        if (vaccineId == null || doseNumber == null) continue;

        history.putIfAbsent(vaccineId, () => []);
        history[vaccineId]!.add({
          'dose_number': doseNumber is int
              ? doseNumber
              : int.tryParse(doseNumber.toString()) ?? 0,
          'activity_date': row['activity_date'],
        });
      }
      return history;
    } catch (e) {
      _logger.e('Error fetching vaccine history: $e');
      return {};
    }
  }
}

/// Provider ที่ดึงประวัติวัคซีนของวัวตัวนั้น (cached 30 นาที)
final cowVaccineHistoryProvider =
    FutureProvider.family<Map<String, List<Map<String, dynamic>>>, int>(
        (ref, cowId) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 30), () => link.close());
  ref.onDispose(() => timer.cancel());

  final service = ref.watch(vaccineServiceProvider);
  return service.fetchVaccineHistory(cowId);
});
