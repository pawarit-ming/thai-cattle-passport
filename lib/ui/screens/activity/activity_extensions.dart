import 'package:flutter/material.dart';
import 'package:th_cow_passport/services/cow_management/models/activity_model.dart';

extension ActivityTypeExtension on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.VACCINE:
        return 'ฉีดวัคซีน';
      case ActivityType.BIRTH:
        return 'การเกิด';
      case ActivityType.TREATMENT:
        return 'การรักษา';
      case ActivityType.EDIT_LOG:
        return 'ประวัติการแก้ไข';
      case ActivityType.PREGNANCY_CHECK:
        return 'ตรวจการตั้งท้อง';
      case ActivityType.BREEDING:
        return 'ผสมพันธุ์';
      case ActivityType.DEATH:
        return 'ตายแล้ว';
      case ActivityType.WEIGHT_UPDATE:
        return 'ปรับปรุงน้ำหนัก';
      case ActivityType.SOLD:
        return 'ขาย';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.VACCINE:
        return Icons.medical_services_outlined;
      case ActivityType.BIRTH:
        return Icons.child_friendly;
      case ActivityType.TREATMENT:
        return Icons.healing;
      case ActivityType.EDIT_LOG:
        return Icons.edit_note;
      case ActivityType.PREGNANCY_CHECK:
        return Icons.pregnant_woman;
      case ActivityType.BREEDING:
        return Icons.favorite;
      case ActivityType.WEIGHT_UPDATE:
        return Icons.monitor_weight;
      case ActivityType.SOLD:
        return Icons.sell;
      case ActivityType.DEATH:
        return Icons.close_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.VACCINE:
        return Colors.blue;
      case ActivityType.BIRTH:
        return Colors.pink;
      case ActivityType.TREATMENT:
        return Colors.orange;
      case ActivityType.EDIT_LOG:
        return Colors.purple;
      case ActivityType.PREGNANCY_CHECK:
        return Colors.green;
      case ActivityType.BREEDING:
        return Colors.red;
      case ActivityType.WEIGHT_UPDATE:
        return Colors.teal;
      case ActivityType.SOLD:
        return Colors.brown;
      case ActivityType.DEATH:
        return Colors.grey;
    }
  }
}
