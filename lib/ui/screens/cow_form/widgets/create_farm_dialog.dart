import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/screens/map/map_picker_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/features/address/presentation/widgets/thai_address_picker.dart';
import 'package:th_cow_passport/services/farm/farm_service.dart';
import 'package:th_cow_passport/supabase_config.dart';
import 'package:th_cow_passport/ui/widgets/common/app_text_field.dart';

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

  final GlobalKey<ThaiAddressPickerState> _addressPickerKey =
      GlobalKey<ThaiAddressPickerState>();

  double? _selectedLat;
  double? _selectedLng;

  /// Tracks whether the submit button should be active.
  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _addressDetailsController.text.trim().isNotEmpty &&
      _provinceController.text.trim().isNotEmpty &&
      _selectedLat != null &&
      _selectedLng != null;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever required text fields change so the submit button
    // enables / disables reactively.
    _nameController.addListener(_onFieldChanged);
    _addressDetailsController.addListener(_onFieldChanged);
    _provinceController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // Trigger a lightweight rebuild to re-evaluate _isFormValid.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _addressDetailsController.removeListener(_onFieldChanged);
    _provinceController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _addressDetailsController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Location helpers
  // ---------------------------------------------------------------------------

  Future<void> _openMapPicker() async {
    // Permission check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ไม่ได้รับการอนุญาตการเข้าถึงตำแหน่ง')),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'การเข้าถึงตำแหน่งถูกปฏิเสธอย่างถาวร กรุณาไปที่การตั้งค่า')),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatitude: _selectedLat,
          initialLongitude: _selectedLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLat = result['lat'] as double?;
        _selectedLng = result['lng'] as double?;

        if (result['province'] != null) {
          _provinceController.text = result['province'] as String;
        }
        if (result['district'] != null) {
          _districtController.text = result['district'] as String;
        }
        if (result['subDistrict'] != null) {
          _subDistrictController.text = result['subDistrict'] as String;
        }
        if (result['postalCode'] != null) {
          _postalCodeController.text = result['postalCode'] as String;
        }
      });

      if (mounted) {
        await _addressPickerKey.currentState?.setAddressFromText(
          result['province'] as String? ?? '',
          result['district'] as String? ?? '',
          result['subDistrict'] as String? ?? '',
          result['postalCode'] as String? ?? '',
        );
      }
    }
  }

  /// Remove the pinned location and reset address fields.
  void _clearLocation() {
    setState(() {
      _selectedLat = null;
      _selectedLng = null;
      _provinceController.text = '';
      _districtController.text = '';
      _subDistrictController.text = '';
      _postalCodeController.text = '';
    });
    // Reset the ThaiAddressPicker selections.
    _addressPickerKey.currentState?.setAddressFromText('', '', '', '');
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: _buildHeader(theme),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Scrollbar(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ข้อมูลทั่วไป
                _buildSectionHeader(context, 'ข้อมูลทั่วไป', Icons.info_outline),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _nameController,
                  label: 'ชื่อฟาร์ม',
                  hintText: 'เช่น ฟาร์มโชคชัย',
                  icon: Icons.agriculture,
                  isRequired: true,
                ),
                SizedBox(height: 24.h),

                // 2. แผนที่
                _buildSectionHeader(
                    context, 'ตำแหน่งที่ตั้ง', Icons.map_outlined),
                SizedBox(height: 12.h),
                _buildMapCard(theme),
                SizedBox(height: 16.h),

                // 3. ข้อมูลที่อยู่
                _buildSectionHeader(
                    context, 'ข้อมูลที่อยู่', Icons.home_outlined),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _addressDetailsController,
                  label: 'รายละเอียดที่อยู่',
                  hintText: 'บ้านเลขที่, หมู่, ซอย, ถนน',
                  icon: Icons.home,
                  maxLines: 2,
                  isRequired: true,
                ),
                SizedBox(height: 16.h),
                ThaiAddressPicker(
                  key: _addressPickerKey,
                  onAddressChanged: (province, district, tambon) {
                    setState(() {
                      _provinceController.text = province?.nameTh ?? '';
                      _districtController.text = district?.nameTh ?? '';
                      _subDistrictController.text = tambon?.nameTh ?? '';
                      _postalCodeController.text =
                          tambon?.zipCode.toString() ?? '';
                    });
                  },
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
      actionsPadding:
          EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          child: Text('ยกเลิก',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          // Disabled (null) when form is incomplete.
          onPressed: _isFormValid ? _handleCreate : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Text('ยืนยันสร้างฟาร์ม',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(Icons.agriculture, color: theme.primaryColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('สร้างฟาร์มใหม่',
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                SizedBox(height: 2.h),
                Text('กรุณากรอกข้อมูลเพื่อเพิ่มฟาร์มของคุณ',
                    style: TextStyle(
                        fontSize: 12.sp, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(ThemeData theme) {
    final hasPinned = _selectedLat != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _openMapPicker,
          borderRadius: BorderRadius.circular(16.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 140.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasPinned
                  ? theme.primaryColor.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              border: Border.all(
                color: hasPinned ? theme.primaryColor : Colors.grey.shade300,
                width: hasPinned ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: hasPinned
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Background Pattern/Icon for empty state
                if (!hasPinned)
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.map_outlined,
                      size: 120.r,
                      color: Colors.grey.shade100,
                    ),
                  ),
                
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: hasPinned
                              ? theme.primaryColor
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          hasPinned ? Icons.location_on : Icons.add_location_alt_outlined,
                          size: 28.r,
                          color: hasPinned ? Colors.white : theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        hasPinned
                            ? 'ปักหมุดตำแหน่งฟาร์มแล้ว'
                            : 'แตะเพื่อเลือกตำแหน่งฟาร์มบนแผนที่',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasPinned ? theme.primaryColor : Colors.black87,
                          fontSize: 14.sp,
                          fontWeight: hasPinned ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (!hasPinned)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'เพื่อให้ระบบกรอกข้อมูลที่อยู่ให้อัตโนมัติ',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (hasPinned)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 12.r),
                          SizedBox(width: 4.w),
                          Text(
                            'Pinned',
                            style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasPinned) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, size: 14.r, color: Colors.grey.shade600),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'พิกัด: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _clearLocation,
                  child: Text(
                    'ล้างตำแหน่ง',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20.w, color: Theme.of(context).primaryColor),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _handleCreate() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Guards are already enforced by _isFormValid (button is disabled),
    // but kept here as a safety net for any programmatic calls.
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

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาปักหมุดตำแหน่งฟาร์มในแผนที่'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final farmService = ref.read(farmServiceProvider);

      final created = await farmService.createFarm(
        userId: userId,
        farmName: _nameController.text.trim(),
        province: _provinceController.text.trim(),
        address: _addressDetailsController.text.trim(),
        district: _districtController.text.trim(),
        subDistrict: _subDistrictController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        latitude: _selectedLat!,
        longitude: _selectedLng!,
      );

      if (!mounted) return;

      if (created == null) {
        // createFarm catches internally and returns null on error.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้างฟาร์ม กรุณาลองใหม่'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      ref.invalidate(userFarmsProvider(userId));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างฟาร์มเรียบร้อยแล้ว')),
      );
    } catch (e) {
      _logger.e(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'เกิดข้อผิดพลาด: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
