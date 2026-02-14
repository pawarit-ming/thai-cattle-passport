import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraWidget extends StatefulWidget {
  final String title;
<<<<<<< Updated upstream
  final String? titleIcon; // asset icon path
  final Function(String) onPictureConfirmed;
=======
>>>>>>> Stashed changes

  const CameraWidget({
    super.key,
    required this.title,
<<<<<<< Updated upstream
    this.titleIcon,
    required this.onPictureConfirmed,
=======
>>>>>>> Stashed changes
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _previewImagePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = "ไม่ได้รับสิทธิ์กล้อง";
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = "ไม่พบกล้อง";
        });
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;

      final image = await _controller!.takePicture();

      setState(() {
        _previewImagePath = image.path;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

    // 🔥 หน้า Preview
    if (_previewImagePath != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ภาพตัวอย่าง")),
        body: Column(
          children: [
            Expanded(
              child: Image.file(
                File(_previewImagePath!),
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _previewImagePath = null;
                      });
                    },
                    child: const Text("ถ่ายใหม่"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final imagePath = _previewImagePath;

                      // 🔥 ปิดกล้องก่อน pop ป้องกันค้าง
                      await _controller?.dispose();
                      _controller = null;

                      if (!mounted) return;

                      Navigator.pop(context, imagePath);
                    },
                    child: const Text("ยืนยัน"),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    // 🔥 หน้า Camera
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return CameraPreview(_controller!);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
