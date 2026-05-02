import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CowVerificationService {
  final logger = Logger();
  final String apiUrl = 'https://sp2025-cow-ai-api.ngrok.app/verify';

  /// ตรวจสอบรูปหน้าที่เพิ่งถ่าย (capturedFacePath) กับรูปหน้า original ทั้งหมด
  /// คืนค่า [true] ถ้าผลลัพธ์ prediction = true มากกว่าครึ่งนึงของจำนวนรูปทั้งหมด
  Future<bool> verifyCowIdentity(
      String capturedFacePath, List<String> originalFaceUrls) async {
    if (originalFaceUrls.isEmpty) return false;

    int passCount = 0;
    int totalCount = originalFaceUrls.length;

    for (int i = 0; i < totalCount; i++) {
      try {
        final url = originalFaceUrls[i];
        logger.i('Verifying against original image ${i + 1}/$totalCount: $url');

        // 1. ดาวน์โหลดรูปภาพ original มาเป็น bytes
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          logger.w('Failed to download image $url');
          continue;
        }
        final originalImageBytes = response.bodyBytes;

        // 2. ส่ง request ให้ AI API
        var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

        request.files.add(http.MultipartFile.fromBytes(
          'image1',
          originalImageBytes,
          filename: 'original_$i.jpg',
        ));

        if (kIsWeb) {
          final res2 = await http.get(Uri.parse(capturedFacePath));
          request.files.add(http.MultipartFile.fromBytes(
            'image2',
            res2.bodyBytes,
            filename: 'captured.jpg',
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image2',
            capturedFacePath,
          ));
        }

        // Accept headers
        request.headers.addAll({
          'accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        });

        // 3. อ่านผลลัพธ์
        final streamedResponse = await request.send();
        final res = await http.Response.fromStream(streamedResponse);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == 'ok') {
            final bool prediction = data['result']['prediction'] ?? false;
            final double distance = (data['result']['distance'] as num).toDouble();
            
            logger.i('API Check ${i + 1}: prediction=$prediction, distance=$distance');

            if (prediction) {
              passCount++;
            }
          }
        } else {
           logger.w('API error ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        logger.e('Error comparing image ${i + 1}: $e');
      }
    }

    logger.i('Verification overall result: Passed $passCount / $totalCount');
    
    // ถ้าเกินครึ่ง (เช่น มี 1 รูป ต้องผ่าน 1, มี 2 รูป ต้องผ่าน 2, มี 3 รูป ต้องผ่าน 2, มี 4 รูป ต้องผ่าน 3)
    return passCount > (totalCount / 2);
  }
}

final cowVerificationServiceProvider = Provider((ref) => CowVerificationService());
