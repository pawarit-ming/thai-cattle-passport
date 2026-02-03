import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:th_cow_passport/ui/screens/camera_screen.dart';

class ImagePickerStep extends StatefulWidget {
  final File? faceImage;
  final File? bodyImage;
  final File? markImage;
  final Function(File) onFaceImageChanged;
  final Function(File) onBodyImageChanged;
  final Function(File) onMarkImageChanged;
  final VoidCallback onNext;

  const ImagePickerStep({
    super.key,
    this.faceImage,
    this.bodyImage,
    this.markImage,
    required this.onFaceImageChanged,
    required this.onBodyImageChanged,
    required this.onMarkImageChanged,
    required this.onNext,
  });

  @override
  State<ImagePickerStep> createState() => _ImagePickerStepState();
}

class _ImagePickerStepState extends State<ImagePickerStep> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(
      ImageSource source, Function(File) onImageSelected) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        onImageSelected(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _navigateAndGetImage(
      String title, Function(File) onImageSelected) async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(baseTitle: title),
      ),
    );

    if (imagePath != null) {
      onImageSelected(File(imagePath));
    }
  }

  void _showImageSourceDialog(String title, Function(File) onImageSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายภาพ'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateAndGetImage(title, onImageSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canContinue = widget.faceImage != null &&
        widget.bodyImage != null &&
        widget.markImage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มวัวใหม่ (ขั้นตอนที่ 1/2)'),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รูปถ่ายระบุตัวตน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
            SizedBox(height: 8.h),
            const Text(
                'กรุณาเพิ่มรูปภาพให้ครบทั้ง 3 รูปเพื่อใช้ในการระบุตัวตน'),
            SizedBox(height: 24.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPhotoPicker(
                      label: 'รูปหน้าตรง',
                      imageFile: widget.faceImage,
                      onTap: () => _showImageSourceDialog(
                          'รูปหน้าตรง', widget.onFaceImageChanged),
                    ),
                    _buildPhotoPicker(
                      label: 'รูปด้านข้างลำตัว',
                      imageFile: widget.bodyImage,
                      onTap: () => _showImageSourceDialog(
                          'รูปด้านข้างลำตัว', widget.onBodyImageChanged),
                    ),
                    _buildPhotoPicker(
                      label: 'รูปขา/ตำหนิ',
                      imageFile: widget.markImage,
                      onTap: () => _showImageSourceDialog(
                          'รูปขา/ตำหนิ', widget.onMarkImageChanged),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('ถัดไป'),
                onPressed: canContinue ? widget.onNext : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdded = imageFile != null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(
                color: isAdded ? colorScheme.primary : Colors.grey.shade300,
                width: isAdded ? 2.w : 1.w,
              ),
              borderRadius: BorderRadius.circular(24.r),
              image: isAdded
                  ? DecorationImage(
                      image: FileImage(imageFile), fit: BoxFit.cover)
                  : null,
            ),
            child: isAdded
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: EdgeInsets.all(8.r),
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 20.r),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Colors.grey.shade600, size: 36.r),
                        SizedBox(height: 8.h),
                        Text(label,
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
