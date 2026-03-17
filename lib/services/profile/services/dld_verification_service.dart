import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:logger/logger.dart';
import 'package:th_cow_passport/supabase_config.dart';

final logger = Logger();

class DldVerificationService {
  static const String _apiUrl =
      'https://eregist.dld.go.th/eregist-portal/api/v1/check/searchFarmer';

  /// ตรวจสอบสถานะเกษตรกรกับ DLD
  /// ส่ง payload formdata key = searchFarmerValue ตามด้วยเลขบัตรประชาชน
  Future<bool> verifyFarmer(String citizenId, String userId) async {
    try {
      logger.i('[DldVerificationService] Verifying farmer with citizenId: $citizenId');

      // DLD ใช้ government CA ที่ Android ไม่รู้จัก ต้องข้าม SSL verification
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      final ioClient = IOClient(httpClient);

      final response = await ioClient.post(
        Uri.parse(_apiUrl),
        body: {
          'searchFarmerValue': citizenId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        logger.i('[DldVerificationService] Response: $data');

        // ตรวจสอบข้อความตอบกลับจาก API ตามที่ระบุ
        // ถ้าผ่านจะขึ้น {"message": "สถานะเกษตรกร | เกษตรกรยืนยันตัวบุคคลแล้ว"}
        bool isVerified = false;

        if (data is Map && data['message'] == "สถานะเกษตรกร | เกษตรกรยืนยันตัวบุคคลแล้ว") {
          isVerified = true;
        }

        if (isVerified) {
          await _updateVerificationStatus(userId, true);
          return true;
        }
      } else {

        logger.e('[DldVerificationService] API Error: ${response.statusCode} - ${response.body}');
      }
      
      return false;
    } catch (e) {
      logger.e('[DldVerificationService] Error during verification', error: e);
      return false;
    }
  }

  /// อัปเดตสถานะการยืนยันใน Supabase
  Future<void> _updateVerificationStatus(String userId, bool isVerified) async {
    try {
      final now = DateTime.now().toIso8601String();
      await supabase.from('users').update({
        'is_dld_verified': isVerified,
        'dld_verified_at': isVerified ? now : null,
      }).eq('id', userId);
      
      logger.i('[DldVerificationService] Successfully updated verification status in database');
    } catch (e) {
      logger.e('[DldVerificationService] Error updating database', error: e);
      rethrow;
    }
  }
}
