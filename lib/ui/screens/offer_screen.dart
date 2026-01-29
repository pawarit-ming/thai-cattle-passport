import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('คำขอเสนอซื้อ'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: 5, // Mock Data: สมมติว่ามี 5 รายการ
        itemBuilder: (context, index) {
          return _buildOfferCard(context, index);
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock Data
    final cowName = 'Bessie ${index + 1}';
    final cowId = '10${index + 1}';
    final bidderName = 'ฟาร์มโชคชัย ${index + 1}';
    final price = '${35 + index * 5},000';
    final date = '1$index ต.ค. 2566';

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // ส่วนหัว: ข้อมูลวัว และ สถานะ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปวัว (Placeholder)
                Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.pets, color: colorScheme.primary, size: 30.r),
                ),
                SizedBox(width: 12.w),
                // รายละเอียดวัว
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cowName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: $cowId • Brahman',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'รอการตอบรับ',
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // ราคาเสนอ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ราคาเสนอ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '฿$price',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 24.h),

            // ข้อมูลผู้เสนอราคา
            Row(
              children: [
                CircleAvatar(
                  radius: 12.r,
                  backgroundColor: colorScheme.secondary.withValues(alpha: 0.2),
                  child: Icon(Icons.person,
                      size: 14.r, color: colorScheme.secondary),
                ),
                SizedBox(width: 8.w),
                Text(
                  'เสนอโดย: $bidderName',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  date,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ปุ่ม Action (ปฏิเสธ / ยอมรับ)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('ปฏิเสธ'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('ยอมรับ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}