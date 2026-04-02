import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:th_cow_passport/services/notification/farm_alert_model.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:logger/logger.dart';

final farmAlertServiceProvider = Provider((ref) => FarmAlertService());

/// Riverpod provider — คำนวณ alerts ทั้งหมดของฟาร์มปัจจุบัน
final farmAlertsProvider = FutureProvider<List<FarmAlert>>((ref) async {
  return ref.watch(farmAlertServiceProvider).computeAlerts();
});

/// Provider สำหรับนับจำนวน alert ที่ยังค้างชำระ (ใช้กับ badge)
final pendingAlertCountProvider = Provider<int>((ref) {
  return ref.watch(farmAlertsProvider).maybeWhen(
        data: (alerts) => alerts.where((a) => !a.isDismissed).length,
        orElse: () => 0,
      );
});

class FarmAlertService {
  /// Set to true to show ALL alerts immediately (ignores time window).
  /// Use this to preview the Notification Center UI without waiting for real dates.
  /// Remember to set back to false before production!
  static const bool kDebugAlerts = true;

  final _client = supabase;
  final _log = Logger();

  // ====== COMPUTE ALL ALERTS ======

  /// คำนวณ alert ทั้งหมดของฟาร์ม โดยดึงข้อมูลจาก Supabase
  Future<List<FarmAlert>> computeAlerts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // ดึงวัวทั้งหมดของ user (ACTIVE + SICK)
      final cowsResponse = await _client
          .from('animals')
          .select('animal_id, animal_name, status')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .inFilter('status', ['ACTIVE', 'SICK']);

      if (cowsResponse.isEmpty) return [];

      final cowIds = cowsResponse
          .map<int>((c) => c['animal_id'] as int)
          .toList();
      final cowNames = <int, String>{
        for (final c in cowsResponse)
          c['animal_id'] as int: c['animal_name'] as String,
      };
      final cowStatuses = <int, String>{
        for (final c in cowsResponse)
          c['animal_id'] as int: c['status'] as String,
      };

      // ดึง activities ทั้งหมดของวัวเหล่านี้ (เฉพาะ type ที่เกี่ยวข้อง)
      final activitiesResponse = await _client
          .from('activities')
          .select('animal_id, activity_type, activity_date, data')
          .inFilter('animal_id', cowIds)
          .inFilter('activity_type',
              ['BREEDING', 'BIRTH', 'SICKNESS', 'VACCINE', 'TREATMENT', 'PREGNANCY_CHECK'])
          .order('activity_date', ascending: false);

      // จัดกลุ่ม activity ล่าสุดของแต่ละ cow × type
      final latestByType = <int, Map<String, Map<String, dynamic>>>{};
      for (final row in activitiesResponse) {
        final cowId = row['animal_id'] as int;
        final type = row['activity_type'] as String;
        latestByType.putIfAbsent(cowId, () => {});
        // เก็บเฉพาะ record แรกที่เจอต่อ type (เนื่องจาก sort DESC จึงเป็น latest)
        latestByType[cowId]!.putIfAbsent(type, () => row);
      }

      // โหลด dismissed state จาก SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      final alerts = <FarmAlert>[];

      for (final cowId in cowIds) {
        final name = cowNames[cowId] ?? 'วัว #$cowId';
        final status = cowStatuses[cowId] ?? 'ACTIVE';
        final byType = latestByType[cowId] ?? {};

        // ── 1. SICK FOLLOW-UP (3 วันหลัง SICKNESS ถ้าสถานะยัง SICK)
        if (status == 'SICK' && byType.containsKey('SICKNESS')) {
          final date =
              DateTime.parse(byType['SICKNESS']!['activity_date'] as String);
          final dueDate = date.add(const Duration(days: 3));
          final alert = _buildAlert(cowId, name, FarmAlertType.sickFollowUp,
              dueDate, prefs);
          if (_shouldInclude(alert)) alerts.add(alert);
        }

        // ── 2. BREEDING — step-based ─────────────────────────────────────────
        // ขั้น 1+2: สังเกตสัด & ตรวจครรภ์ → แสดงเมื่อยังไม่มี PREGNANCY_CHECK
        // ขั้น 3:   ใกล้คลอด → แสดงเมื่อมี PREGNANCY_CHECK แล้ว (ยืนยันตั้งท้อง)
        if (byType.containsKey('BREEDING')) {
          final breedDate = DateTime.parse(
              byType['BREEDING']!['activity_date'] as String);

          final pregCheckRow = byType['PREGNANCY_CHECK'];
          final pregCheckIsValid = pregCheckRow != null &&
              DateTime.parse(pregCheckRow['activity_date'] as String)
                  .isAfter(breedDate);

          if (!pregCheckIsValid) {
            // ขั้น 1: สังเกตการเป็นสัด (19 วันหลังผสม)
            final heatDue = breedDate.add(const Duration(days: 19));
            if (_isWithinWindow(heatDue, 7)) {
              final alert = _buildAlert(
                  cowId, name, FarmAlertType.heatCheck, heatDue, prefs);
              if (_shouldInclude(alert)) alerts.add(alert);
            }

            // ขั้น 2: ตรวจครรภ์ (90 วันหลังผสม)
            final pregDue = breedDate.add(const Duration(days: 90));
            if (_isWithinWindow(pregDue, 14)) {
              final alert = _buildAlert(
                  cowId, name, FarmAlertType.pregnancyCheck, pregDue, prefs);
              if (_shouldInclude(alert)) alerts.add(alert);
            }
          } else {
            // ขั้น 3: ใกล้คลอด (270 วัน) — เฉพาะเมื่อตั้งท้องยืนยันแล้ว
            final birthDue = breedDate.add(const Duration(days: 270));
            if (_isWithinWindow(birthDue, 14)) {
              final alert = _buildAlert(
                  cowId, name, FarmAlertType.nearBirth, birthDue, prefs);
              if (_shouldInclude(alert)) alerts.add(alert);
            }
          }
        }

        // ── 3. BIRTH → WEANING (90 วันหลังคลอด)
        if (byType.containsKey('BIRTH')) {
          final birthDate =
              DateTime.parse(byType['BIRTH']!['activity_date'] as String);
          final weanDue = birthDate.add(const Duration(days: 90));
          if (_isWithinWindow(weanDue, 14)) {
            final alert = _buildAlert(
                cowId, name, FarmAlertType.weaningDue, weanDue, prefs);
            if (_shouldInclude(alert)) alerts.add(alert);
          }
        }

        // ── 4. VACCINE OVERDUE (ถ้าเลยกำหนด booster > 7 วัน)
        if (byType.containsKey('VACCINE')) {
          final vaccineData = byType['VACCINE']!;
          final data = vaccineData['data'] as Map<String, dynamic>? ?? {};
          final nextDoseStr = data['next_dose_date'] as String?;

          if (nextDoseStr != null) {
            final nextDose = DateTime.tryParse(nextDoseStr);
            if (nextDose != null && nextDose.isBefore(DateTime.now())) {
              final alert = _buildAlert(
                  cowId, name, FarmAlertType.vaccineOverdue, nextDose, prefs);
              if (_shouldInclude(alert)) alerts.add(alert);
            }
          }
          // fallback: ถ้าไม่มี next_dose_date — notification ถูก schedule ผ่าน NotificationService แล้ว
        }
      }

      // จัดเรียง: overdue ก่อน → วันนี้ → เร็วๆ นี้
      alerts.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      _log.i('FarmAlertService: computed ${alerts.length} alerts');
      return alerts;
    } catch (e) {
      _log.e('FarmAlertService.computeAlerts error: $e');
      return [];
    }
  }

  // ====== PERSISTENCE ======

  /// Mark alert as dismissed (เก็บลง SharedPreferences)
  Future<void> dismissAlert(FarmAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(alert.persistKey, true);
    alert.isDismissed = true;
  }

  /// ยกเลิกการ dismiss (undo)
  Future<void> undoDismiss(FarmAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(alert.persistKey);
    alert.isDismissed = false;
  }

  /// ล้าง dismissed state ทั้งหมด (สำหรับ debug)
  Future<void> clearAllDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('farm_alert_dismissed_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  // ====== HELPERS ======

  FarmAlert _buildAlert(int cowId, String cowName, FarmAlertType type,
      DateTime dueDate, SharedPreferences prefs) {
    final id = '${cowId}_${type.name}_${dueDate.toIso8601String().substring(0, 10)}';
    final dismissed = prefs.getBool('farm_alert_dismissed_$id') ?? false;
    return FarmAlert(
      id: id,
      cowId: cowId,
      cowName: cowName,
      type: type,
      dueDate: dueDate,
      isDismissed: dismissed,
    );
  }

  /// ตรวจสอบว่า dueDate อยู่ใน window (±windowDays หรือเลยกำหนดไม่เกิน 30 วัน)
  /// เมื่อ kDebugAlerts = true จะแสดงทุก alert โดยไม่รอ window จริง
  bool _isWithinWindow(DateTime dueDate, int windowDays) {
    if (kDebugAlerts) return true;
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    return diff <= windowDays && diff >= -30;
  }

  /// แสดง alert ถ้ายังไม่ dismiss
  bool _shouldInclude(FarmAlert alert) => !alert.isDismissed;
}
