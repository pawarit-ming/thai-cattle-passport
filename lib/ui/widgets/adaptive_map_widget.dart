import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_api_availability/google_api_availability.dart';

/// Cached GMS availability result (checked once per app session)
bool? _gmsAvailable;

Future<bool> isGmsAvailable() async {
  if (_gmsAvailable != null) return _gmsAvailable!;

  // iOS always works with Google Maps SDK (no GMS needed)
  if (!Platform.isAndroid) {
    _gmsAvailable = true;
    return true;
  }

  try {
    final availability = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability();
    _gmsAvailable = availability == GooglePlayServicesAvailability.success;
  } catch (_) {
    _gmsAvailable = false;
  }
  return _gmsAvailable!;
}

// ─────────────────────────────────────────────────
// Display-only map (e.g. SellerDetailsSheet)
// ─────────────────────────────────────────────────
class AdaptiveDisplayMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String markerId;
  final String markerTitle;
  final VoidCallback? onMarkerTap;
  final double zoom;

  const AdaptiveDisplayMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.markerId,
    this.markerTitle = '',
    this.onMarkerTap,
    this.zoom = 15,
  });

  @override
  State<AdaptiveDisplayMap> createState() => _AdaptiveDisplayMapState();
}

class _AdaptiveDisplayMapState extends State<AdaptiveDisplayMap> {
  bool? _useGoogleMap;

  @override
  void initState() {
    super.initState();
    _checkGms();
  }

  Future<void> _checkGms() async {
    final result = await isGmsAvailable();
    if (mounted) setState(() => _useGoogleMap = result);
  }

  @override
  Widget build(BuildContext context) {
    if (_useGoogleMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_useGoogleMap!) {
      return _buildGoogleMap();
    } else {
      return _buildFlutterMap();
    }
  }

  Widget _buildGoogleMap() {
    final pos = gmap.LatLng(widget.latitude, widget.longitude);
    return gmap.GoogleMap(
      initialCameraPosition:
          gmap.CameraPosition(target: pos, zoom: widget.zoom),
      markers: {
        gmap.Marker(
          markerId: gmap.MarkerId(widget.markerId),
          position: pos,
          infoWindow: gmap.InfoWindow(
            title: widget.markerTitle,
            snippet: 'กดที่นี่เพื่อนำทาง',
          ),
          onTap: widget.onMarkerTap,
        ),
      },
      myLocationButtonEnabled: false,
      mapType: gmap.MapType.normal,
    );
  }

  Widget _buildFlutterMap() {
    final center = ll.LatLng(widget.latitude, widget.longitude);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: widget.zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.th_cow_passport',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40.r,
              height: 40.r,
              child: GestureDetector(
                onTap: widget.onMarkerTap,
                child: Icon(Icons.location_on, color: Colors.red, size: 40.r),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Interactive map with tap-to-place marker (e.g. CreateFarmDialog)
// ─────────────────────────────────────────────────
class AdaptivePickerMap extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final ValueChanged<({double lat, double lng})> onLocationSelected;
  final VoidCallback?
      onMapCreated; // Optional: called when google map is created

  const AdaptivePickerMap({
    super.key,
    this.initialLatitude = 13.7563,
    this.initialLongitude = 100.5018,
    this.initialZoom = 10,
    this.selectedLatitude,
    this.selectedLongitude,
    required this.onLocationSelected,
    this.onMapCreated,
  });

  @override
  State<AdaptivePickerMap> createState() => AdaptivePickerMapState();
}

class AdaptivePickerMapState extends State<AdaptivePickerMap> {
  bool? _useGoogleMap;
  gmap.GoogleMapController? _googleMapController;
  final MapController _flutterMapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkGms();
  }

  Future<void> _checkGms() async {
    final result = await isGmsAvailable();
    if (mounted) setState(() => _useGoogleMap = result);
  }

  /// Animate to a specific location (called externally, e.g. GPS button)
  void animateTo(double lat, double lng, {double zoom = 16}) {
    if (_useGoogleMap == true && _googleMapController != null) {
      _googleMapController!.animateCamera(
        gmap.CameraUpdate.newLatLngZoom(gmap.LatLng(lat, lng), zoom),
      );
    } else {
      _flutterMapController.move(ll.LatLng(lat, lng), zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useGoogleMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_useGoogleMap!) {
      return _buildGoogleMap();
    } else {
      return _buildFlutterMap();
    }
  }

  Widget _buildGoogleMap() {
    final initPos =
        gmap.LatLng(widget.initialLatitude, widget.initialLongitude);
    final selectedPos =
        (widget.selectedLatitude != null && widget.selectedLongitude != null)
            ? gmap.LatLng(widget.selectedLatitude!, widget.selectedLongitude!)
            : null;

    return gmap.GoogleMap(
      initialCameraPosition: gmap.CameraPosition(
        target: initPos,
        zoom: widget.initialZoom,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapType: gmap.MapType.normal,
      onMapCreated: (controller) {
        _googleMapController = controller;
        widget.onMapCreated?.call();
      },
      onTap: (latLng) {
        widget
            .onLocationSelected((lat: latLng.latitude, lng: latLng.longitude));
      },
      markers: selectedPos == null
          ? {}
          : {
              gmap.Marker(
                markerId: const gmap.MarkerId('farm_loc'),
                position: selectedPos,
                infoWindow: const gmap.InfoWindow(title: 'ตำแหน่งฟาร์ม'),
              ),
            },
    );
  }

  Widget _buildFlutterMap() {
    final initCenter =
        ll.LatLng(widget.initialLatitude, widget.initialLongitude);
    final selectedPos =
        (widget.selectedLatitude != null && widget.selectedLongitude != null)
            ? ll.LatLng(widget.selectedLatitude!, widget.selectedLongitude!)
            : null;

    return FlutterMap(
      mapController: _flutterMapController,
      options: MapOptions(
        initialCenter: initCenter,
        initialZoom: widget.initialZoom,
        onTap: (tapPosition, latLng) {
          widget.onLocationSelected(
              (lat: latLng.latitude, lng: latLng.longitude));
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.th_cow_passport',
        ),
        if (selectedPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: selectedPos,
                width: 40.r,
                height: 40.r,
                child: Icon(Icons.location_on, color: Colors.red, size: 40.r),
              ),
            ],
          ),
      ],
    );
  }
}
