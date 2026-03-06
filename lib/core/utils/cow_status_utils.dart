import 'package:flutter/material.dart';

/// Shared utility for cow status labels and colors.
/// Use this in ALL screens to ensure consistent status display.
class CowStatusUtils {
  CowStatusUtils._();

  static String getLabel(String? status) {
    switch (status) {
      case 'ACTIVE':
        return 'สุขภาพดี';
      case 'SICK':
        return 'ป่วย';
      case 'SOLD':
        return 'ขายแล้ว';
      case 'DEATH':
        return 'ตายแล้ว';
      default:
        return 'ไม่ระบุ';
    }
  }

  static Color getColor(String? status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF4CAF50); // Muted green
      case 'SICK':
        return const Color(0xFFE6A23C); // Warm amber
      case 'SOLD':
        return const Color(0xFF5C6BC0); // Muted indigo
      case 'DEATH':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String? status) {
    switch (status) {
      case 'ACTIVE':
        return Icons.favorite_rounded;
      case 'SICK':
        return Icons.local_hospital_rounded;
      case 'SOLD':
        return Icons.sell_rounded;
      case 'DEATH':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_outline;
    }
  }
}
