import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CowDetailScreen extends StatelessWidget {
  const CowDetailScreen({super.key});

  // ฟังก์ชันสำหรับแสดง Overlay ข้อมูลเจ้าของ
  void _showOwnerOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // ช่วยให้จัดการขนาด overlay ได้ดีขึ้นถ้าข้อมูลเยอะ
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ให้ขนาดพอดีกับเนื้อหา
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'ข้อมูลเจ้าของและสถานที่',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ส่วนข้อมูลเจ้าของ
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('คุณสมชาย ใจดี',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Text('โทร: 081-234-5678',
                  style: TextStyle(color: Colors.grey)),

              const Divider(height: 32), // เส้นคั่นส่วน

              // --- ส่วนข้อมูลสถานที่อยู่ของวัวที่เพิ่มเข้ามา ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'สถานที่อยู่ของวัว:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ฟาร์มโชคชัย เลขที่ 123 หมู่ 5 ต.หนองน้ำแดง อ.ปากช่อง จ.นครราชสีมา 30130',
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // -------------------------------------------

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('ปิด'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // โค้ดสำหรับติดต่อเจ้าของ หรือเปิดแผนที่
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('ติดต่อเจ้าของ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Cow Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/edit-form/101'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(theme, 'Tag ID:', '101'),
                _buildDetailRow(theme, 'Name:', 'Bessie'),
                _buildDetailRow(theme, 'Breed:', 'Brahman'),
                _buildDetailRow(theme, 'Date of Birth:', '2023-01-15'),
                _buildDetailRow(theme, 'Dam (Mother):', '502'),
                _buildDetailRow(theme, 'Sire (Father):', '007'),
              ],
            ),
          ),
        ),
      ),
      // ปุ่มเสนอซื้อด้านล่าง
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showOwnerOverlay(context), // เรียกใช้ Overlay
            icon: const Icon(Icons.shopping_cart),
            label:
                const Text('เสนอซื้อวัวตัวนี้', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting cow identification...')),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
