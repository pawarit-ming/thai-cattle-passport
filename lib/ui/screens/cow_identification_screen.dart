import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CowIdentificationScreen extends StatefulWidget {
  const CowIdentificationScreen({super.key});

  @override
  State<CowIdentificationScreen> createState() => _CowIdentificationScreenState();
}

class _CowIdentificationScreenState extends State<CowIdentificationScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  int _currentStep = 0;
  final List<String> _imagePaths = [];
  final List<String> _steps = ["หน้าวัว", "ตัววัว", "ขาวัว"];
  bool _cameraInitialized = false;
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
        setState(() {
          _cameraError = "No cameras available.";
        });
        return;
      }

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _cameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = "Failed to initialize camera: ${e.toString()}";
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_cameraInitialized || _controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _initializeControllerFuture;

      final image = await _controller!.takePicture();

      if (!mounted) return;

      setState(() {
        _previewImagePath = image.path;
      });
    } catch (e) {
      print(e);
    }
  }

  void _confirmPicture() async {
    if (_previewImagePath == null) return;

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/th_cow_passport';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.png';

    final File newImage = await File(_previewImagePath!).copy(filePath);

    setState(() {
      _imagePaths.add(newImage.path);
      _previewImagePath = null;
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        // All pictures taken, navigate to a summary or back
        Navigator.of(context).pop(_imagePaths);
      }
    });
  }

  void _retakePicture() {
    setState(() {
      _previewImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_previewImagePath != null) {
      return Scaffold(
        appBar: AppBar(title: Text('ภาพตัวอย่าง - ${_steps[_currentStep]}')),
        body: Column(
          children: [
            Expanded(
              child: Image.file(File(_previewImagePath!)),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _retakePicture,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.red,
                    ),
                    child: const Text('ถ่ายใหม่'),
                  ),
                  ElevatedButton(
                    onPressed: _confirmPicture,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green,
                    ),
                    child: const Text('ยืนยัน'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('ระบุตัวตนวัว - ${_steps[_currentStep]}')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_cameraError != null) {
              return Center(child: Text(_cameraError!));
            }
            if (_controller == null || !_controller!.value.isInitialized) {
              return const Center(child: Text("กำลังโหลดกล้อง..."));
            }
            return CameraPreview(_controller!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
