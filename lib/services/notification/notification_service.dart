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
}
