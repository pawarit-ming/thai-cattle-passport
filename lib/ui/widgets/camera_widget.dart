import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';

class CameraWidget extends StatefulWidget {
  final String title;
  final Function(String) onPictureConfirmed;

  const CameraWidget({
    super.key,
    required this.title,
    required this.onPictureConfirmed,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  final logger = Logger();
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _cameraError;
  String? _previewImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = "No cameras available.";
            logger.e(_cameraError);
          });
        }
        return;
      }

      final firstCamera = cameras.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      logger.i("Camera initialized successfully.");
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = "Failed to initialize camera: ${e.toString()}";
          logger.e(_cameraError, error: e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      logger.d("Picture taken: ${image.path}");
      if (!mounted) return;
      setState(() {
        _previewImagePath = image.path;
      });
    } catch (e) {
      logger.e("Error taking picture: $e", error: e);
    }
  }

  void _confirmPicture() {
    if (_previewImagePath == null) return;
    logger.d("Confirming picture: $_previewImagePath");
    widget.onPictureConfirmed(_previewImagePath!);
    if (mounted) {
      setState(() {
        _previewImagePath = null;
      });
    }
  }

  void _retakePicture() {
    logger.d("Retaking picture.");
    setState(() {
      _previewImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _previewImagePath == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _retakePicture();
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(_previewImagePath != null
                ? 'ภาพตัวอย่าง - ${widget.title}'
                : widget.title)),
        body: _buildBody(),
        floatingActionButton: _previewImagePath == null && _cameraError == null
            ? GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 72.r,
                  width: 72.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 4.w,
                    ),
                  ),
                  padding: EdgeInsets.all(4.r),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildBody() {
    if (_initializeControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraError != null) {
      return Center(child: Text(_cameraError!));
    }

    if (_previewImagePath != null) {
      return Column(
        children: [
          Expanded(
            child: Image.file(File(_previewImagePath!), fit: BoxFit.contain),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _retakePicture,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('ถ่ายใหม่'),
                ),
                ElevatedButton.icon(
                  onPressed: _confirmPicture,
                  icon: const Icon(Icons.check),
                  label: const Text('ยืนยัน'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_controller != null && _controller!.value.isInitialized) {
            return CameraPreview(_controller!);
          }
          return const Center(child: Text("Error initializing camera"));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
