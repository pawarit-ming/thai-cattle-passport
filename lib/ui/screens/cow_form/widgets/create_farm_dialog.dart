import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';
import 'package:th_cow_passport/supabase_config.dart';

class CreateFarmDialog extends ConsumerStatefulWidget {
  const CreateFarmDialog({super.key});

  @override
  ConsumerState<CreateFarmDialog> createState() => _CreateFarmDialogState();
}

class _CreateFarmDialogState extends ConsumerState<CreateFarmDialog> {
  final _nameController = TextEditingController();
  final _provinceController = TextEditingController();
  final _logger = Logger();

  @override
  void dispose() {
    _nameController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: const Text('สร้างฟาร์มใหม่'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('กรุณากรอกข้อมูลเบื้องต้นเพื่อสร้างฟาร์ม'),
          SizedBox(height: 16.h),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'ชื่อฟาร์ม *',
              hintText: 'เช่น ฟาร์มโชคชัย',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: defaultBorder,
              enabledBorder: defaultBorder,
              focusedBorder: focusedBorder,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _provinceController,
            decoration: InputDecoration(
              labelText: 'จังหวัด *',
              hintText: 'เช่น นครราชสีมา',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: defaultBorder,
              enabledBorder: defaultBorder,
              focusedBorder: focusedBorder,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _handleCreate,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ),
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }

  Future<void> _handleCreate() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (_nameController.text.trim().isEmpty ||
        _provinceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อฟาร์มและจังหวัด'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await supabase.from('farms').insert({
        'user_id': userId,
        'farm_name': _nameController.text.trim(),
        'province': _provinceController.text.trim(),
      });

      if (mounted) {
        ref.invalidate(userFarmsProvider(userId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างฟาร์มเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      _logger.e(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
