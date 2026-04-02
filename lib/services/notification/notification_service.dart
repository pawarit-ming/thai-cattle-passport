import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';

class NotificationService {
  /// Set to true to fire notifications 1 minute from now (for testing).
  /// Remember to set back to false before production!
  static const bool kDebugNotification = true;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _logger = Logger();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service. Call once in main().
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Request permissions for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    _logger.i('NotificationService initialized');
  }

  /// Schedule a vaccine reminder notification.
  ///
  /// [notificationId] - Unique ID (use cowId * 1000 + vaccine hash)
  /// [cowName] - ชื่อวัว
  /// [vaccineName] - ชื่อวัคซีน
  /// [scheduledDate] - วันนัดฉีด
  Future<void> scheduleVaccineReminder({
    required int notificationId,
    required String cowName,
    required String vaccineName,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await initialize();

    // Debug: fire 5 seconds from now. Production: 1 day before due date.
    final reminderDate = kDebugNotification
        ? DateTime.now().add(const Duration(seconds: 5))
        : scheduledDate.subtract(const Duration(days: 1));

    // Don't schedule if the date is already past
    if (reminderDate.isBefore(DateTime.now())) {
      _logger.w(
          'Skipping notification: reminder date $reminderDate is in the past');
      return;
    }

    final tzDateTime = tz.TZDateTime.from(reminderDate, tz.local);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'แจ้งเตือนวัคซีน 💉',
      body: '$cowName ถึงกำหนดฉีด $vaccineName พรุ่งนี้',
      scheduledDate: tzDateTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccine_reminders',
          'แจ้งเตือนวัคซีน',
          channelDescription: 'แจ้งเตือนกำหนดฉีดวัคซีนวัว',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    _logger.i(
        'Scheduled vaccine reminder #$notificationId for $cowName ($vaccineName) on $reminderDate');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  /// DEBUG ONLY: Fires a notification immediately (no scheduling).
  /// Call this to verify the plugin is initialized and permissions are granted.
  Future<void> showImmediateTest() async {
    if (!_initialized) await initialize();
    await _plugin.show(
      id: 9999,
      title: '🐄 ทดสอบการแจ้งเตือน',
      body: 'ถ้าเห็นข้อความนี้ แสดงว่า plugin ทำงานปกติ',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccine_reminders',
          'แจ้งเตือนวัคซีน',
          channelDescription: 'แจ้งเตือนกำหนดฉีดวัคซีนวัว',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    _logger.i('showImmediateTest: notification sent');
  }

  /// Generate a unique notification ID from cowId and vaccineId
  static int generateNotificationId(int cowId, String vaccineId) {
    return cowId * 1000 + vaccineId.hashCode.abs() % 1000;
  }

  /// Generate a unique notification ID from cowId and a string suffix
  static int generateIdFromSuffix(int cowId, String suffix) {
    return (cowId * 10000 + suffix.hashCode.abs() % 10000).abs();
  }

  // ====== BREEDING REMINDERS ======

  /// เตือนสังเกตการเป็นสัด (18-21 วันหลังผสม)
  Future<void> scheduleHeatCheckReminder({
    required int cowId,
    required String cowName,
    required DateTime breedingDate,
  }) async {
    final reminderDate = kDebugNotification
        ? DateTime.now().add(const Duration(seconds: 5))
        : breedingDate.add(const Duration(days: 19));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _scheduleRaw(
      id: generateIdFromSuffix(cowId, 'heat_check'),
      title: 'สังเกตการเป็นสัด',
      body: '$cowName อาจกำลังเป็นสัด — ควรสังเกตพฤติกรรม',
      at: reminderDate,
    );
  }

  /// เตือนตรวจสอบการตั้งท้อง (90 วันหลังผสม)
  Future<void> schedulePregnancyCheckReminder({
    required int cowId,
    required String cowName,
    required DateTime breedingDate,
  }) async {
    final reminderDate = kDebugNotification
        ? DateTime.now().add(const Duration(seconds: 10))
        : breedingDate.add(const Duration(days: 90));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _scheduleRaw(
      id: generateIdFromSuffix(cowId, 'preg_check'),
      title: 'ตรวจสอบการตั้งท้อง',
      body: '$cowName ถึงเวลาตรวจครรภ์ (90 วันหลังผสม)',
      at: reminderDate,
    );
  }

  /// เตือนใกล้กำหนดคลอด (270 วันหลังผสม)
  Future<void> scheduleNearBirthReminder({
    required int cowId,
    required String cowName,
    required DateTime breedingDate,
  }) async {
    final reminderDate = kDebugNotification
        ? DateTime.now().add(const Duration(seconds: 15))
        : breedingDate.add(const Duration(days: 270));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _scheduleRaw(
      id: generateIdFromSuffix(cowId, 'near_birth'),
      title: 'ใกล้กำหนดคลอด',
      body: '$cowName ใกล้ถึงกำหนดคลอด — เตรียมพื้นที่และอุปกรณ์ให้พร้อม',
      at: reminderDate,
    );
  }

  // ====== BIRTH REMINDERS ======

  /// เตือนถึงกำหนดหย่านม (90 วันหลังคลอด)
  Future<void> scheduleWeaningReminder({
    required int cowId,
    required String cowName,
    required DateTime birthDate,
  }) async {
    final reminderDate = kDebugNotification
        ? DateTime.now().add(const Duration(seconds: 20))
        : birthDate.add(const Duration(days: 90));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _scheduleRaw(
      id: generateIdFromSuffix(cowId, 'weaning'),
      title: 'ถึงกำหนดหย่านม',
      body: '$cowName ถึงเวลาหย่านมลูกโค (90 วันหลังคลอด)',
      at: reminderDate,
    );
  }

  // ====== SICKNESS REMINDERS ======

  /// เตือนติดตามอาการป่วย (3 วันหลังบันทึก SICKNESS)
  Future<void> scheduleSicknessFollowUpReminder({
    required int cowId,
    required String cowName,
    required DateTime sicknessDate,
  }) async {
    final reminderDate = kDebugNotification
        ? DateTime.now().add(const Duration(seconds: 5))
        : sicknessDate.add(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;
    await _scheduleRaw(
      id: generateIdFromSuffix(cowId, 'sick_followup'),
      title: 'ติดตามอาการป่วย',
      body: '$cowName — ควรตรวจสอบอาการและบันทึกผลการรักษา',
      at: reminderDate,
    );
  }

  // ====== INTERNAL HELPERS ======

  Future<void> _scheduleRaw({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!_initialized) await initialize();
    final tzDateTime = tz.TZDateTime.from(at, tz.local);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'farm_reminders',
          'แจ้งเตือนฟาร์ม',
          channelDescription: 'แจ้งเตือนกิจกรรมสำคัญของฟาร์ม',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    _logger.i('Scheduled: $title (#$id) at $at');
  }
}
