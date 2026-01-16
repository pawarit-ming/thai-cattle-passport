import 'package:flutter/material.dart';

class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('คำขอเสนอซื้อ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
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
    final date = '1${index} ต.ค. 2566';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ส่วนหัว: ข้อมูลวัว และ สถานะ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปวัว (Placeholder)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.pets, color: colorScheme.primary, size: 30),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'รอการตอบรับ',
                          style: TextStyle(
                              fontSize: 10,
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
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // ข้อมูลผู้เสนอราคา
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: colorScheme.secondary.withOpacity(0.2),
                  child: Icon(Icons.person,
                      size: 14, color: colorScheme.secondary),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),

            // ปุ่ม Action (ปฏิเสธ / ยอมรับ)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ปฏิเสธ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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