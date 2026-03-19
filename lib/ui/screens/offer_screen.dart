import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:th_cow_passport/ui/widgets/common/app_shimmer.dart';
import 'package:th_cow_passport/ui/widgets/common/app_empty_state.dart';
import 'cow_detail_screen.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final _supabase = Supabase.instance.client;

  // 1. เปลี่ยนจาก Stream เป็น Future
  late Future<List<Map<String, dynamic>>> _offersFuture;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th');
    // 2. เรียกโหลดข้อมูลครั้งแรก
    _offersFuture = _fetchOffers();
  }

  // 3. แยกฟังก์ชันดึงข้อมูลออกมา เพื่อให้เรียกซ้ำได้
  Future<List<Map<String, dynamic>>> _fetchOffers() {
    final myUserId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('offers')
        .select() // ใช้ select ธรรมดา (ไม่ใช่ stream)
        .eq('seller_id', myUserId ?? '')
        .order('created_at', ascending: false);
  }

  // --- ฟังก์ชันแสดงตัวเลือกเมื่อกดยอมรับ ---
  void _showAcceptOptions(
      BuildContext context, String offerId, String animalId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เลือกรูปแบบหลังการขาย',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 24.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const Icon(Icons.local_shipping_outlined,
                      color: Colors.blue, size: 30),
                  title: const Text('ส่งมอบทันที',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('เปลี่ยนสถานะวัวเป็น "ขายแล้ว"'),
                  onTap: () {
                    Navigator.pop(context); // ปิดหน้าต่าง
                    _updateStatus(offerId, animalId, 'accepted',
                        deliveryType: 'delivery');
                  },
                ),
                SizedBox(height: 12.h),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const Icon(Icons.house_siding,
                      color: Colors.orange, size: 30),
                  title: const Text('ฝากเลี้ยง',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('เปลี่ยนสถานะวัวเป็น "ฝากเลี้ยง"'),
                  onTap: () {
                    Navigator.pop(context); // ปิดหน้าต่าง
                    _updateStatus(offerId, animalId, 'accepted',
                        deliveryType: 'foster');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- ฟังก์ชันอัปเดตสถานะ ---
  Future<void> _updateStatus(String offerId, String animalId, String newStatus,
      {String? deliveryType}) async {
    try {
      // 1. อัปเดตสถานะคำขอในตาราง offers
      Map<String, dynamic> offerUpdate = {'status': newStatus};

      // (Optional) หากคุณสร้างคอลัมน์ใหม่ในตาราง offers เพื่อเก็บรูปแบบ ให้ปลดคอมเมนต์ด้านล่าง
      // if (deliveryType != null) {
      //   offerUpdate['delivery_type'] = deliveryType;
      // }

      await _supabase.from('offers').update(offerUpdate).eq('id', offerId);

      // 2. อัปเดตสถานะวัวในตาราง animals
      if (newStatus == 'accepted') {
        // กำหนดสถานะตามที่เลือก
        String finalAnimalStatus = 'SOLD'; // ค่าเริ่มต้นคือส่งมอบ (ขายขาด)
        if (deliveryType == 'foster') {
          finalAnimalStatus =
              'FOSTER'; // เปลี่ยนเป็นสถานะฝากเลี้ยง (คุณสามารถเปลี่ยนคำนี้ตามที่ตั้งไว้ใน DB ได้)
        }

        await _supabase.from('animals').update({
          'status': finalAnimalStatus,
        }).eq('animal_id', animalId);
      }

      // 3. สั่งรีเฟรชหน้าจอหลังทำรายการเสร็จ
      setState(() {
        _offersFuture = _fetchOffers();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตสถานะเป็น $newStatus เรียบร้อย')),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  // --- ฟังก์ชันลบรายการเดียว ---
  Future<void> _deleteOffer(String offerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันลบรายการ?'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('offers').delete().eq('id', offerId);

      // 5. สั่งรีเฟรชหน้าจอทันทีหลังลบเสร็จ
      setState(() {
        _offersFuture = _fetchOffers();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
        );
      }
    }
  }

  // --- ฟังก์ชันลบประวัติทั้งหมด ---
  Future<void> _clearAllHistory() async {
    final myUserId = _supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างประวัติ?'),
        content: const Text(
            'คุณต้องการลบรายการที่ "ยอมรับ" และ "ปฏิเสธ" แล้วทั้งหมดใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('offers')
            .delete()
            .eq('seller_id', myUserId)
            .neq('status', 'pending');

        // 6. สั่งรีเฟรชหน้าจอทันทีหลังลบทั้งหมดเสร็จ
        setState(() {
          _offersFuture = _fetchOffers();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ล้างประวัติเรียบร้อยแล้ว')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คำขอเสนอซื้อ'),
        actions: [
          IconButton(
            onPressed: _clearAllHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'ล้างประวัติที่ดำเนินการแล้ว',
          ),
        ],
      ),
      // 7. เปลี่ยน StreamBuilder เป็น FutureBuilder
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _offersFuture, // ใช้ตัวแปร Future แทน
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: AppShimmer(
                    child: Container(
                      height: 160.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final offers = snapshot.data ?? [];
          if (offers.isEmpty) {
            return const AppEmptyState(
              title: 'ไม่มีรายการคำขอเสนอซื้อ',
              subtitle: 'เมื่อมีผู้ซื้อเสนอซื้อวัวของคุณ รายการจะแสดงที่นี่',
              imageAsset: 'assets/images/cow.png',
            );
          }
          // เพิ่ม RefreshIndicator ให้ลากลงเพื่อรีเฟรชได้ด้วย
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _offersFuture = _fetchOffers();
              });
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                return _buildOfferCard(context, offers[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, Map<String, dynamic> offer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final animalId = offer['animal_id'];

    return FutureBuilder(
        future: Future.wait([
          _supabase.from('animals').select().eq('animal_id', animalId).single(),
          _supabase
              .from('users')
              .select('first_name, last_name')
              .eq('id', offer['buyer_id'])
              .maybeSingle(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final animalData = snapshot.hasData ? snapshot.data![0] : null;
          final buyerData = snapshot.hasData ? snapshot.data![1] : null;

          final cowName = animalData?['animal_name'] ?? 'กำลังโหลด...';
          final breed = animalData?['breed'] ?? '-';

          String? image;
          if (animalData?['face_pic'] != null) {
            if (animalData['face_pic'] is List &&
                (animalData['face_pic'] as List).isNotEmpty) {
              image = animalData['face_pic'][0];
            } else if (animalData['face_pic'] is String) {
              image = animalData['face_pic'];
            }
          }

          final status = offer['status'] ?? 'pending';
          final buyerId = offer['buyer_id'];

          final buyerFirstName = buyerData?['first_name']?.toString() ?? '';
          final buyerLastName = buyerData?['last_name']?.toString() ?? '';
          final buyerNameDisplay = buyerFirstName.isNotEmpty
              ? '$buyerFirstName $buyerLastName'.trim()
              : '${buyerId.toString().substring(0, 5)}...';

          final createdAt =
              DateTime.tryParse(offer['created_at'] ?? '') ?? DateTime.now();
          final dateStr = DateFormat('d MMM yyyy', 'th').format(createdAt);

          Color statusColor = Colors.orange;
          String statusText = 'รอการตอบรับ';
          if (status == 'accepted') {
            statusColor = Colors.green;
            statusText = 'ยอมรับแล้ว';
          } else if (status == 'rejected') {
            statusColor = Colors.red;
            statusText = 'ปฏิเสธแล้ว';
          }

          final isCompleted = status != 'pending';

          // ตรวจสอบว่าโหลดข้อมูลวัวเสร็จเรียบร้อยแล้วหรือไม่
          final hasData = snapshot.hasData && animalData != null;

          return Card(
            margin: EdgeInsets.only(bottom: 16.h),
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            // เพิ่ม clipBehavior เพื่อให้เอฟเฟกต์การกด (Ripple) อยู่ภายในขอบมนของการ์ด
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: hasData
                  ? () {
                      // ใช้ Navigator.of(context, rootNavigator: true)
                      // เพื่อบอกว่าให้เปิดหน้าใหม่ทับ Navbar ไปเลย
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => CowDetailScreen(
                            cowId: animalId, // ส่งค่าตามปกติ
                            // animal: animalData, // ถ้าจำเป็นต้องส่ง
                          ),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60.r,
                          height: 60.r,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.r),
                            image: (image != null && image.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(image),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: (image == null || image.isEmpty)
                              ? Icon(Icons.pets,
                                  color: colorScheme.primary, size: 30.r)
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cowName,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              Text('สายพันธุ์: $breed',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey.shade600)),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                      color:
                                          statusColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(statusText,
                                    style: TextStyle(
                                        fontSize: 10.sp,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        // ปุ่มลบรายการ (แสดงเฉพาะรายการที่จบกระบวนการแล้ว)
                        if (isCompleted)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            onPressed: () =>
                                _deleteOffer(offer['id'].toString()),
                            tooltip: 'ลบรายการนี้',
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 14.r, color: colorScheme.secondary),
                        SizedBox(width: 8.w),
                        Text('ผู้ซื้อ: $buyerNameDisplay',
                            style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        Text(dateStr,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey)),
                      ],
                    ),
                    if (!isCompleted) ...[
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(
                                  offer['id'].toString(),
                                  animalId.toString(),
                                  'rejected'),
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
                              onPressed: () => _showAcceptOptions(context,
                                  offer['id'].toString(), animalId.toString()),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: const Text('ยอมรับ'),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        });
  }
}
