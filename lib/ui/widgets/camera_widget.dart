import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraWidget extends StatefulWidget {
  final String title;
  final String? titleIcon; // asset icon path
  final Function(String) onPictureConfirmed;

  const CameraWidget({
    super.key,
    required this.title,
    this.titleIcon,
    required this.onPictureConfirmed,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _previewImagePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // จัดการกล้องเมื่อมีการสลับแอป
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) setState(() => _error = "ไม่ได้รับสิทธิ์กล้อง");
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = "ไม่พบกล้อง");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high, // แนะนำ High เพื่อความชัด
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;

      // ปิด Flash หรือ Focus ก่อนถ่ายถ้าจำเป็น
      final image = await _controller!.takePicture();

      if (mounted) {
        setState(() {
          _previewImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _retakePicture() {
    setState(() {
      _previewImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ PopScope เพื่อจัดการปุ่ม Back ของ Android
    return PopScope(
      canPop: _previewImagePath == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _retakePicture();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.titleIcon != null) ...[
                Image.asset(
                  widget.titleIcon!,
                  width: 28,
                  height: 28,
                  // ถ้า Icon เป็นสีอยู่แล้ว ไม่ต้องใส่ color ก็ได้
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  _previewImagePath != null
                      ? 'ตัวอย่าง - ${widget.title}'
                      : widget.title,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        body: _buildContent(),
        // แสดงปุ่มถ่ายรูปเฉพาะตอนที่ยังไม่ได้ถ่าย และไม่มี error
        floatingActionButton: (_previewImagePath == null && _error == null)
            ? FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildContent() {
    // 1. กรณีมี Error
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: _initCamera,
                child: const Text("ลองใหม่"),
              )
            ],
          ),
        ),
      );
    }

    // 2. กรณี Loading
    if (_initializeControllerFuture == null ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3. หน้า Preview (แสดงรูปที่ถ่ายแล้ว)
    if (_previewImagePath != null) {
      return Column(
        children: [
          Expanded(
            child: Image.file(
              File(_previewImagePath!),
              fit: BoxFit.contain,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _retakePicture,
                  icon: const Icon(Icons.refresh),
                  label: const Text("ถ่ายใหม่"),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_previewImagePath != null) {
                      widget.onPictureConfirmed(_previewImagePath!);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("ยืนยัน"),
                ),
              ],
            ),
          )
        ],
      );
    }

    // 4. หน้า Camera Preview (เลนส์กล้อง)
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CameraPreview(_controller!),
    );
  }
}