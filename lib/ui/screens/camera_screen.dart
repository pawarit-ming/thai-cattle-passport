import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:th_cow_passport/ui/widgets/camera_widget.dart';

class CameraScreen extends StatefulWidget {
  final String baseTitle;
  final List<String>? steps;

  const CameraScreen({
    super.key,
    required this.baseTitle,
    this.steps,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final logger = Logger();
  int _currentStep = 0;
  final List<String> _imagePaths = [];

  bool get _isMultiStep => widget.steps != null && widget.steps!.isNotEmpty;

  Future<void> _onPictureConfirmed(String imagePath) async {
    // Save the temporary image to a permanent location
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/th_cow_passport';
    await Directory(dirPath).create(recursive: true);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final String filePath = '$dirPath/$fileName';

    final File newImage = await File(imagePath).copy(filePath);
    logger.d("Image saved to: ${newImage.path}");

    if (!mounted) return;

    if (_isMultiStep) {
      _imagePaths.add(newImage.path);
      if (_currentStep < widget.steps!.length - 1) {
        setState(() {
          _currentStep++;
        });
        logger.d("Moving to next step: ${widget.steps![_currentStep]}");
      } else {
        logger.d("Finished all steps, returning images: $_imagePaths");
        Navigator.of(context).pop(_imagePaths);
      }
    } else {
      // Single step mode: pop immediately with the single image path string
      logger.d("Single step mode finished, returning image: ${newImage.path}");
      Navigator.of(context).pop(newImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = widget.baseTitle;
    if (_isMultiStep) {
      currentTitle = '${widget.baseTitle} - ${widget.steps![_currentStep]}';
    }

    return CameraWidget(
      title: currentTitle,
      onPictureConfirmed: _onPictureConfirmed,
    );
  }
}