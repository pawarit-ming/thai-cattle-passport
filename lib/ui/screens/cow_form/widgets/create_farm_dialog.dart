import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/features/address/presentation/widgets/thai_address_picker.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';

class CreateFarmDialog extends ConsumerStatefulWidget {
  const CreateFarmDialog({super.key});

  @override
  ConsumerState<CreateFarmDialog> createState() => _CreateFarmDialogState();
}

class _CreateFarmDialogState extends ConsumerState<CreateFarmDialog> {
  final _nameController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _subDistrictController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _logger = Logger();

  @override
  void dispose() {
    _nameController.dispose();
    _addressDetailsController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: const Text('สร้างฟาร์มใหม่'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณากรอกข้อมูลเบื้องต้นเพื่อสร้างฟาร์ม'),
            SizedBox(height: 16.h),
            StyledTextField(
              controller: _nameController,
              label: 'ชื่อฟาร์ม',
              icon: Icons.agriculture,
              isRequired: true,
              hintText: 'เช่น ฟาร์มโชคชัย',
            ),
            SizedBox(height: 12.h),
            StyledTextField(
              controller: _addressDetailsController,
              label: 'รายละเอียดที่อยู่',
              hintText: 'บ้านเลขที่, หมู่, ถนน, ซอย',
              icon: Icons.home,
              maxLines: 2,
              isRequired: true,
            ),
            SizedBox(height: 12.h),
            ThaiAddressPicker(
              onAddressChanged: (province, district, tambon) {
                setState(() {
                  _provinceController.text = province?.nameTh ?? '';
                  _districtController.text = district?.nameTh ?? '';
                  _subDistrictController.text = tambon?.nameTh ?? '';
                  _postalCodeController.text = tambon?.zipCode.toString() ?? '';
                });
              },
            ),
            // Hidden fields for standard display if needed, but ThaiAddressPicker handles them mostly.
            // We can optionally show them as read-only fields if standard style prefers transparency.
            // For now, mirroring RegisterScreen implies reliance on the picker mostly,
            // but we might want to check if RegisterScreen shows them.
            // Checking RegisterScreen code again: it doesn't show them explicitly after the picker
            // in the snippet provided in `task.md` or recent views.
            // Wait, in RegisterScreen step 2 code:
            // It has _provinceController etc. but ThaiAddressPicker updates them.
            // Does RegisterScreen SHOW them?
            // Looking at `_buildFarmStep` in RegisterScreen:
            // It shows `StyledTextField` for farm name, addressDetails.
            // Then `ThaiAddressPicker`.
            // It DOES NOT show separate text fields for province/district/etc.
            // ThaiAddressPicker likely contains its own dropdowns.
            // So we just need to ensure we capture the values.
          ],
        ),
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
        _provinceController.text.trim().isEmpty ||
        _addressDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อฟาร์ม ที่อยู่ และเลือกจังหวัด'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final farmService = ref.read(farmServiceProvider);
      await farmService.createFarm(
        userId: userId,
        farmName: _nameController.text.trim(),
        province: _provinceController.text.trim(),
        address: _addressDetailsController.text.trim(),
        district: _districtController.text.trim(),
        subDistrict: _subDistrictController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

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
