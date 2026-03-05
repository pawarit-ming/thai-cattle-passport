import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ Import ที่ขาดหายไป

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final logger = Logger();
  bool _isScanned = false;
  final MobileScannerController controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);

      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบ QR Code ในรูปภาพนี้')),
          );
        }
      } else {
        final String? code = capture.barcodes.first.rawValue;
        if (code != null && mounted) {
          setState(() {
            _isScanned = true;
          });
          logger.d('QR Code Found from Image: $code');
          Navigator.pop(context, code);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  logger.d('QR Code Found: ${barcode.rawValue}');
                  setState(() {
                    _isScanned = true;
                  });
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),

          // ปุ่มไอคอนรูปภาพที่มุมซ้ายล่าง
          Positioned(
            left: 24.w, // ✅ ตอนนี้จะรู้จัก .w แล้ว
            bottom: 24.h, // ✅ ตอนนี้จะรู้จัก .h แล้ว
            child: FloatingActionButton(
              onPressed: _pickImage,
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              child: const Icon(Icons.photo_library),
            ),
          ),
        ],
      ),
    );
  }
}
