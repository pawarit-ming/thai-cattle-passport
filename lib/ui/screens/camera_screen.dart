import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:th_cow_passport/ui/widgets/camera_widget.dart';

class CameraScreen extends StatefulWidget {
  final String baseTitle;
  final List<String>? steps;
  final List<String>? stepIcons; // asset paths per step

  const CameraScreen({
    super.key,
    required this.baseTitle,
    this.steps,
    this.stepIcons,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final logger = Logger();
  int _currentStep = 0;
  final List<String> _imagePaths = [];

  bool get _isMultiStep => widget.steps != null && widget.steps!.isNotEmpty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    String currentTitle = widget.baseTitle;

    if (_isMultiStep) {
      currentTitle =
          '${widget.baseTitle} - ${widget.steps![_currentStep]}';
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraWidget(title: currentTitle),
      ),
    );

    if (result == null) return;

    try {
      final Directory extDir =
          await getApplicationDocumentsDirectory();

      final String dirPath =
          '${extDir.path}/Pictures/th_cow_passport';

      await Directory(dirPath).create(recursive: true);

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.png';

      final String filePath = '$dirPath/$fileName';

      final File newImage =
          await File(result).copy(filePath);

      if (!mounted) return;

      if (_isMultiStep) {
        _imagePaths.add(newImage.path);

        if (_currentStep < widget.steps!.length - 1) {
          setState(() {
            _currentStep++;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _openCamera();
            }
          });
        } else {
          Navigator.of(context).pop(_imagePaths);
        }
      } else {
        Navigator.of(context).pop(newImage.path);
      }
    } catch (e) {
      logger.e("Error saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    String currentTitle = widget.baseTitle;
    String? currentIcon;
    if (_isMultiStep) {
      currentTitle =
          '${widget.steps![_currentStep]} (${_currentStep + 1}/${widget.steps!.length})';
      if (widget.stepIcons != null && _currentStep < widget.stepIcons!.length) {
        currentIcon = widget.stepIcons![_currentStep];
      }
    }

    return CameraWidget(
      title: currentTitle,
      titleIcon: currentIcon,
      onPictureConfirmed: _onPictureConfirmed,
=======
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
>>>>>>> Stashed changes
    );
  }
}
