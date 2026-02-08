import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // เพิ่ม: สำหรับแผนที่
import 'package:geolocator/geolocator.dart'; // เพิ่ม: สำหรับหาตำแหน่งปัจจุบัน
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

  // --- ส่วนจัดการแผนที่ ---
  GoogleMapController? _mapController;
  LatLng? _selectedLocation; // ตัวแปรเก็บพิกัดที่เลือก
  bool _isGettingLocation = false; // สถานะตอนกำลังโหลด GPS

  // พิกัดเริ่มต้น (อนุสาวรีย์ชัยฯ - หรือจุดกลางประเทศไทย)
  static const LatLng _defaultLocation = LatLng(13.7563, 100.5018);

  @override
  void dispose() {
    _nameController.dispose();
    _addressDetailsController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _postalCodeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ฟังก์ชันหาตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. เช็คว่าเปิด GPS หรือยัง
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'กรุณาเปิด GPS บนมือถือของท่าน';
      }

      // 2. เช็ค Permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'แอปไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'การเข้าถึงตำแหน่งถูกปิดถาวร กรุณาตั้งค่าใน Setting';
      }

      // 3. ดึงพิกัด
      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = latLng;
      });

      // เลื่อนกล้องไปที่ตำแหน่งปัจจุบัน
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: const Text('สร้างฟาร์มใหม่'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรุณากรอกข้อมูลเบื้องต้นเพื่อสร้างฟาร์ม'),
            SizedBox(height: 16.h),

            // 1. ชื่อฟาร์ม
            StyledTextField(
              controller: _nameController,
              label: 'ชื่อฟาร์ม',
              icon: Icons.agriculture,
              isRequired: true,
              hintText: 'เช่น ฟาร์มโชคชัย',
            ),
            SizedBox(height: 12.h),

            // 2. รายละเอียดที่อยู่
            StyledTextField(
              controller: _addressDetailsController,
              label: 'รายละเอียดที่อยู่',
              hintText: 'บ้านเลขที่, หมู่, ถนน, ซอย',
              icon: Icons.home,
              maxLines: 2,
              isRequired: true,
            ),
            SizedBox(height: 12.h),

            // --- ส่วนแผนที่ (เพิ่มใหม่) ---
            Text('ตำแหน่งที่ตั้งฟาร์ม *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Container(
              height: 200.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: _defaultLocation,
                        zoom: 10,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false, // เราทำปุ่มกดเอง
                      zoomControlsEnabled: true,
                      mapType: MapType.normal,
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: (latLng) {
                        setState(() {
                          _selectedLocation = latLng;
                        });
                      },
                      markers: _selectedLocation == null
                          ? {}
                          : {
                              Marker(
                                markerId: const MarkerId('farm_loc'),
                                position: _selectedLocation!,
                                infoWindow:
                                    const InfoWindow(title: 'ตำแหน่งฟาร์ม'),
                              ),
                            },
                    ),
                    // ปุ่มกดหาตำแหน่งปัจจุบัน
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        backgroundColor: Colors.white,
                        onPressed:
                            _isGettingLocation ? null : _getCurrentLocation,
                        child: _isGettingLocation
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).primaryColor),
                              )
                            : Icon(Icons.my_location,
                                color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedLocation != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'พิกัด: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.green),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'กรุณากดปุ่ม GPS หรือแตะที่แผนที่เพื่อปักหมุด',
                  style: TextStyle(fontSize: 12.sp, color: Colors.orange),
                ),
              ),
            SizedBox(height: 16.h),
            // ---------------------------

            // 3. ตัวเลือกที่อยู่ (จังหวัด/อำเภอ/ตำบล)
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

    // Validation: ต้องมีชื่อฟาร์ม, ที่อยู่, จังหวัด และ "พิกัด"
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

    if (_selectedLocation == null) {
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

      // ส่งข้อมูลเข้า Service (รวม Latitude/Longitude)
      await farmService.createFarm(
        userId: userId,
        farmName: _nameController.text.trim(),
        province: _provinceController.text.trim(),
        address: _addressDetailsController.text.trim(),
        district: _districtController.text.trim(),
        subDistrict: _subDistrictController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        // ต้องตรวจสอบว่า FarmService ของคุณรองรับพารามิเตอร์ 2 ตัวนี้แล้วหรือยัง
        // (ตามที่เราคุยกันก่อนหน้านี้ ให้ไปแก้ FarmService ด้วยครับ)
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
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
