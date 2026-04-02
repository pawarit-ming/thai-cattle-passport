// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// ประเภทของการแจ้งเตือนฟาร์ม
enum FarmAlertType {
  sickFollowUp, // ติดตามอาการป่วย (3 วันหลัง SICKNESS)
  nearBirth, // ใกล้คลอด (~270 วันหลังผสม)
  pregnancyCheck, // ตรวจครรภ์ (90 วันหลังผสม)
  heatCheck, // สังเกตการเป็นสัด (18-21 วันหลังผสม/คลอด)
  weaningDue, // ถึงกำหนดหย่านม (90 วันหลังคลอด)
  vaccineOverdue, // วัคซีนค้างชำระ (เลยกำหนด booster)
}

extension FarmAlertTypeExt on FarmAlertType {
  String get titleTh {
    switch (this) {
      case FarmAlertType.sickFollowUp:
        return 'ติดตามอาการป่วย';
      case FarmAlertType.nearBirth:
        return 'ใกล้ถึงกำหนดคลอด';
      case FarmAlertType.pregnancyCheck:
        return 'ตรวจสอบการตั้งท้อง';
      case FarmAlertType.heatCheck:
        return 'สังเกตการเป็นสัด';
      case FarmAlertType.weaningDue:
        return 'ถึงกำหนดหย่านม';
      case FarmAlertType.vaccineOverdue:
        return 'วัคซีนเลยกำหนด';
    }
  }

  /// Asset icon (ถ้ามี) แบบเดียวกับ ActivityCard
  String? get assetIcon {
    switch (this) {
      case FarmAlertType.nearBirth:
        return 'assets/images/calf.png';
      default:
        return null;
    }
  }

  // Emoji property removed to match Activity screen format

  String getDescription(String cowName, DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now()).inDays;
    final dayStr =
        diff < 0 ? 'เลยกำหนด ${diff.abs()} วัน' : 'อีก $diff วัน';
    switch (this) {
      case FarmAlertType.sickFollowUp:
        return '$cowName ควรติดตามอาการ ($dayStr)';
      case FarmAlertType.nearBirth:
        return '$cowName ใกล้ถึงกำหนดคลอด ($dayStr)';
      case FarmAlertType.pregnancyCheck:
        return '$cowName ถึงเวลาตรวจครรภ์ ($dayStr)';
      case FarmAlertType.heatCheck:
        return '$cowName อาจเป็นสัด — ควรสังเกต ($dayStr)';
      case FarmAlertType.weaningDue:
        return '$cowName ถึงกำหนดหย่านมลูก ($dayStr)';
      case FarmAlertType.vaccineOverdue:
        return '$cowName มีวัคซีนที่เลยกำหนด ($dayStr)';
    }
  }

  /// Material icon — ใช้เหมือนกับ ActivityCard
  IconData get icon {
    switch (this) {
      case FarmAlertType.heatCheck:
        return Icons.favorite;
      case FarmAlertType.pregnancyCheck:
        return Icons.check_rounded;
      case FarmAlertType.nearBirth:
        return Icons.pets;
      case FarmAlertType.weaningDue:
        return Icons.water_drop_outlined;
      case FarmAlertType.sickFollowUp:
        return Icons.sick;
      case FarmAlertType.vaccineOverdue:
        return Icons.medical_services_outlined;
    }
  }

  /// สีของ icon — ตรงกับ ActivityTypeExtension.color
  Color get iconColor {
    switch (this) {
      case FarmAlertType.heatCheck:
        return Colors.red;
      case FarmAlertType.pregnancyCheck:
        return Colors.green;
      case FarmAlertType.nearBirth:
        return Colors.pink;
      case FarmAlertType.weaningDue:
        return Colors.teal;
      case FarmAlertType.sickFollowUp:
        return Colors.red;
      case FarmAlertType.vaccineOverdue:
        return Colors.blue;
    }
  }
}

/// ระดับความเร่งด่วน
enum AlertUrgency {
  overdue, // เลยกำหนดแล้ว (แดง)
  today, // วันนี้ (เหลือง)
  upcoming, // ภายใน 7 วัน (เขียว)
}

class FarmAlert {
  final String id; // unique key = "${cowId}_${type.name}_${dueDate}"
  final int cowId;
  final String cowName;
  final FarmAlertType type;
  final DateTime dueDate;
  bool isDismissed;

  FarmAlert({
    required this.id,
    required this.cowId,
    required this.cowName,
    required this.type,
    required this.dueDate,
    this.isDismissed = false,
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now());

  AlertUrgency get urgency {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return AlertUrgency.overdue;
    if (diff == 0) return AlertUrgency.today;
    return AlertUrgency.upcoming;
  }

  /// สร้าง unique persistent key สำหรับ SharedPreferences
  String get persistKey => 'farm_alert_dismissed_$id';
}
