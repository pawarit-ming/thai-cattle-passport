import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final List<String> _capturedImagePaths = [];

  bool get _isMultiStep => widget.steps != null && widget.steps!.isNotEmpty;

  /// ฟังก์ชันจัดการเมื่อผู้ใช้กดยืนยันรูปภาพจาก CameraWidget
  Future<void> _onPictureConfirmed(String tempPath) async {
    try {
      String finalImagePath = tempPath;

      if (!kIsWeb) {
        // 1. เตรียม Path สำหรับบันทึกไฟล์ถาวร
        final Directory extDir = await getApplicationDocumentsDirectory();
        final String dirPath = '${extDir.path}/Pictures/th_cow_passport';
        await Directory(dirPath).create(recursive: true);

        // สร้างชื่อไฟล์ไม่ซ้ำกัน
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_step$_currentStep.jpg';
        final String filePath = '$dirPath/$fileName';

        // 2. Copy ไฟล์จาก Cache ของกล้องไปยัง Folder ของแอพ
        final File newImage = await File(tempPath).copy(filePath);
        logger.i("Saved image at: ${newImage.path}");
        finalImagePath = newImage.path;
      } else {
        logger.i("Web mode: kept image URL: $tempPath");
      }

      if (!mounted) return;

      // 3. Logic การเปลี่ยน Step
      if (_isMultiStep) {
        _capturedImagePaths.add(finalImagePath);

        if (_currentStep < widget.steps!.length - 1) {
          // ยังไม่ครบทุกขั้นตอน -> ไปขั้นตอนถัดไป
          setState(() {
            _currentStep++;
          });
        } else {
          // ครบแล้ว -> ส่ง List รูปภาพกลับ
          Navigator.of(context).pop(_capturedImagePaths);
        }
      } else {
        // กรณีถ่ายรูปเดียว -> ส่ง Path รูปเดียวกลับ
        Navigator.of(context).pop(finalImagePath);
      }
    } catch (e) {
      logger.e("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("บันทึกภาพไม่สำเร็จ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = widget.baseTitle;
    String? currentIcon;

    if (_isMultiStep) {
      // ตัวอย่าง: "หน้าตรง (1/4)"
      currentTitle =
          '${widget.steps![_currentStep]} (${_currentStep + 1}/${widget.steps!.length})';

      if (widget.stepIcons != null && _currentStep < widget.stepIcons!.length) {
        currentIcon = widget.stepIcons![_currentStep];
      }
    }

    return Scaffold(
      // ใช้ Scaffold ที่นี่เพื่อให้พื้นหลังเป็นสีมาตรฐานระหว่างเปลี่ยน Step
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CameraWidget(
          // 🔥 สำคัญมาก: Key เปลี่ยน = Widget ถูกสร้างใหม่ = กล้อง Reset ตัวเองอัตโนมัติ
          key: ValueKey(_currentStep),
          title: currentTitle,
          titleIcon: currentIcon,
          onPictureConfirmed: _onPictureConfirmed,
        ),
      ),
    );
  }
}
