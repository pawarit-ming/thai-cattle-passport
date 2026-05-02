import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/adaptive_map_widget.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  double? _selectedLat;
  double? _selectedLng;
  bool _isFetchingLocation = false;
  bool _isGeocodingLocation = false;

  final GlobalKey<AdaptivePickerMapState> _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLatitude;
    _selectedLng = widget.initialLongitude;
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
      });
      _mapKey.currentState
          ?.animateTo(position.latitude, position.longitude, zoom: 16);
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('ไม่สามารถดึงตำแหน่งปัจจุบันได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  /// Strip Thai administrative-level prefixes that the geocoding package
  /// prepends to district / sub-district names on some devices.
  ///
  /// Examples:  "เขตพระนคร" → "พระนคร"
  ///            "แขวงพระบรมมหาราชวัง" → "พระบรมมหาราชวัง"
  ///            "อำเภอเมืองเชียงใหม่" → "เมืองเชียงใหม่"
  ///            "ตำบลสุเทพ" → "สุเทพ"
  String _stripThaiAdminPrefix(String name) {
    const prefixes = ['กิ่งอำเภอ', 'อำเภอ', 'เขต', 'แขวง', 'ตำบล'];
    for (final prefix in prefixes) {
      if (name.startsWith(prefix)) {
        return name.substring(prefix.length).trim();
      }
    }
    return name;
  }

  /// Reverse-geocode [lat,lng] then pop with the full address map.
  Future<void> _confirmLocation() async {
    final lat = _selectedLat;
    final lng = _selectedLng;
    if (lat == null || lng == null) return;

    setState(() => _isGeocodingLocation = true);
    try {
      String province = '';
      String district = '';
      String subDistrict = '';
      String postalCode = '';

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // geocoding returns Thai admin level names for Thai coordinates:
        // administrativeArea  → จังหวัด
        // subAdministrativeArea → อำเภอ / เขต  (may have prefix e.g. "เขตพระนคร")
        // locality / subLocality → ตำบล / แขวง (may have prefix e.g. "แขวงบางรัก")
        province = p.administrativeArea ?? '';
        district = _stripThaiAdminPrefix(p.subAdministrativeArea ?? '');
        final rawSubDistrict = p.subLocality?.isNotEmpty == true
            ? p.subLocality!
            : (p.locality ?? '');
        subDistrict = _stripThaiAdminPrefix(rawSubDistrict);
        postalCode = p.postalCode ?? '';
      }

      if (mounted) {
        Navigator.pop(context, {
          'lat': lat,
          'lng': lng,
          'province': province,
          'district': district,
          'subDistrict': subDistrict,
          'postalCode': postalCode,
        });
      }
    } catch (_) {
      // Geocoding failed — still return coordinates so the farm can be created.
      if (mounted) {
        Navigator.pop(context, {
          'lat': lat,
          'lng': lng,
          'province': '',
          'district': '',
          'subDistrict': '',
          'postalCode': '',
        });
      }
    } finally {
      if (mounted) setState(() => _isGeocodingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกตำแหน่งบนแผนที่',
            style: TextStyle(fontSize: 18.sp)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AdaptivePickerMap(
            key: _mapKey,
            initialLatitude: widget.initialLatitude ?? 13.7563,
            initialLongitude: widget.initialLongitude ?? 100.5018,
            selectedLatitude: _selectedLat,
            selectedLongitude: _selectedLng,
            onLocationSelected: (loc) {
              setState(() {
                _selectedLat = loc.lat;
                _selectedLng = loc.lng;
              });
            },
          ),

          // GPS floating button — bottom-right
          Positioned(
            bottom: _selectedLat != null ? 110.h : 30.h,
            right: 20.w,
            child: FloatingActionButton(
              heroTag: 'gps_fab',
              mini: true,
              onPressed:
                  _isFetchingLocation ? null : _goToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 4,
              tooltip: 'ตำแหน่งปัจจุบัน',
              child: _isFetchingLocation
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).primaryColor),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Confirm button — shown after a pin is placed
          if (_selectedLat != null && _selectedLng != null)
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _isGeocodingLocation ? null : _confirmLocation,
                child: _isGeocodingLocation
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'ยืนยันตำแหน่งนี้',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
