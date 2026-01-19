import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data: รายการกิจกรรมที่เกิดขึ้นกับวัวตัวนี้
    final List<Map<String, dynamic>> activities = [
      {
        'date': '15 ต.ค. 2566',
        'time': '10:30',
        'title': 'ฉีดวัคซีนปากเท้าเปื่อย',
        'description': 'ฉีดเข็มกระตุ้น โดย สัตวแพทย์สมชาย',
        'type': 'vaccine',
      },
      {
        'date': '10 ก.ย. 2566',
        'time': '09:00',
        'title': 'บันทึกน้ำหนัก',
        'description': 'น้ำหนักปัจจุบัน: 450 กก. (+15 กก. จากเดือนที่แล้ว)',
        'type': 'weight',
      },
      {
        'date': '01 ส.ค. 2566',
        'time': '14:20',
        'title': 'ย้ายคอก',
        'description': 'ย้ายจากคอกอนุบาล ไปยัง คอกขุน 1',
        'type': 'move',
      },
      {
        'date': '20 ก.ค. 2566',
        'time': '08:45',
        'title': 'ตรวจสุขภาพประจำปี',
        'description': 'สุขภาพแข็งแรงสมบูรณ์ ไม่พบพยาธิ',
        'type': 'checkup',
      },
      {
        'date': '15 ม.ค. 2566',
        'time': '11:00',
        'title': 'ลงทะเบียนวัวใหม่',
        'description': 'นำเข้าสู่ระบบ Cow Passport',
        'type': 'register',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _buildTimelineItem(context, activities[index],
            isLast: index == activities.length - 1);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, Map<String, dynamic> item,
      {required bool isLast}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // กำหนดสีและไอคอนตามประเภทกิจกรรม
    IconData icon;
    Color color;
    switch (item['type']) {
      case 'vaccine':
        icon = Icons.medical_services_outlined;
        color = Colors.blue;
        break;
      case 'weight':
        icon = Icons.monitor_weight_outlined;
        color = Colors.orange;
        break;
      case 'move':
        icon = Icons.local_shipping_outlined;
        color = Colors.purple;
        break;
      case 'checkup':
        icon = Icons.health_and_safety_outlined;
        color = Colors.green;
        break;
      case 'register':
        icon = Icons.app_registration;
        color = colorScheme.primary;
        break;
      default:
        icon = Icons.circle_outlined;
        color = Colors.grey;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนเส้น Timeline ด้านซ้าย
          Column(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 20.r),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          // ส่วนเนื้อหา
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['date'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        item['time'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item['title'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Text(
                      item['description'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}