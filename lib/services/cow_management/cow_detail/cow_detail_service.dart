import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import '../../../supabase_config.dart';
import 'package:logger/logger.dart';

final cowDetailServiceProvider =
    ChangeNotifierProvider((ref) => CowDetailService());

class CowDetailService extends ChangeNotifier {
  final logger = Logger();
  Cow? _currentCow;
  bool _isLoading = false;

  Cow? get currentCow => _currentCow;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 1. Fetch ข้อมูลวัวรายตัวตาม ID
  Future<void> fetchCowById(int id) async {
    _setLoading(true);
    try {
      final response = await supabase
          .from('animals')
          .select()
          .eq('animal_id', id)
          .single(); // ดึงมาแค่แถวเดียว

      _currentCow = Cow.fromMap(response);
      logger.d("Fetched detail for cow: ${_currentCow?.animalName}");
    } catch (e) {
      logger.e('Error fetching cow detail: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 2. ฟังก์ชันแก้ไขข้อมูลวัว (Update)
  Future<String?> updateCow(Cow updatedCow,
      {File? newFacePic, File? newBodyPic, File? newMarkPic}) async {
    _setLoading(true);
    try {
      // Prepare lists (initially from the model, or empty if null)
      List<String> faceUrls = List.from(updatedCow.facePic ?? []);
      List<String> bodyUrls = List.from(updatedCow.bodyPic ?? []);
      List<String> markUrls = List.from(updatedCow.markPic ?? []);

      final nidNumber = updatedCow.nidNumber ?? 'unknown';

      // Upload new images and REPLACE the first item if exists (or add if empty)
      // Since the UI currently supports only one image per category, we treat the first item as the main one.
      if (newFacePic != null) {
        final url = await _uploadImage(newFacePic, nidNumber, 'face');
        if (url != null) {
          faceUrls = [url]; // Replace with new list containing the new URL
        }
      }
      if (newBodyPic != null) {
        final url = await _uploadImage(newBodyPic, nidNumber, 'body');
        if (url != null) {
          bodyUrls = [url];
        }
      }
      if (newMarkPic != null) {
        final url = await _uploadImage(newMarkPic, nidNumber, 'mark');
        if (url != null) {
          markUrls = [url];
        }
      }

      final dataToUpdate = {
        'animal_name': updatedCow.animalName,
        'nid_number': updatedCow.nidNumber,
        'breed': updatedCow.breed,
        'color': updatedCow.color,
        'weight': updatedCow.weight,
        'height': updatedCow.height,
        'dam_id': updatedCow.damId,
        'dam_name': updatedCow.damName,
        'sire_id': updatedCow.sireId,
        'sire_name': updatedCow.sireName,
        'birth_date': updatedCow.birthDate?.toIso8601String(),
        'sex': updatedCow.sex,
        'status': updatedCow.status,
        'face_pic': faceUrls,
        'body_pic': bodyUrls,
        'mark_pic': markUrls,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('animals')
          .update(dataToUpdate)
          .eq('animal_id', updatedCow.animalId!);

      // Update local state with the new URLs
      _currentCow = updatedCow.copyWith(
        facePic: faceUrls,
        bodyPic: bodyUrls,
        markPic: markUrls,
      );

      logger.i("Cow updated successfully: ${updatedCow.animalName}");
      return null;
    } on PostgrestException catch (e) {
      logger.e('Error updating cow: $e');
      if (e.code == '22003') {
        // numeric_field_overflow
        return 'ข้อมูลตัวเลข (เช่น น้ำหนัก, ส่วนสูง) มีค่ามากเกินไป';
      }
      return e.message;
    } catch (e) {
      logger.e('Error updating cow: $e');
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 3. ฟังก์ชันเพิ่มวัวใหม่ (Add)
  Future<bool> addCow(Cow cow,
      {File? bodyPic, File? facePic, File? markPic}) async {
    _setLoading(true);
    try {
      List<String>? bodyPicUrls;
      List<String>? facePicUrls;
      List<String>? markPicUrls;
      final nidNumber = cow.nidNumber ?? 'unknown';

      // Upload images if provided
      if (bodyPic != null) {
        final url = await _uploadImage(bodyPic, nidNumber, 'body');
        if (url != null) bodyPicUrls = [url];
      }
      if (facePic != null) {
        final url = await _uploadImage(facePic, nidNumber, 'face');
        if (url != null) facePicUrls = [url];
      }
      if (markPic != null) {
        final url = await _uploadImage(markPic, nidNumber, 'mark');
        if (url != null) markPicUrls = [url];
      }

      final cowWithImages = cow.copyWith(
        bodyPic: bodyPicUrls,
        facePic: facePicUrls,
        markPic: markPicUrls,
      );

      final data = cowWithImages.toMapForInsert();
      logger.d("Adding new cow with NID: ${cow.nidNumber}");
      await supabase.from('animals').insert(data);

      logger.i("Cow added successfully: ${cow.nidNumber}");
      return true;
    } catch (e) {
      logger.e('Error adding cow: $e', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันช่วยอัปโหลดรูป (เหมือนใน CowService)
  Future<String?> _uploadImage(
      File imageFile, String cowNid, String type) async {
    try {
      final fileName =
          '${type}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final String path = '${SupabaseConfig.bucketName}/$cowNid/$fileName';

      await supabase.storage.from(SupabaseConfig.bucketName).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return supabase.storage
          .from(SupabaseConfig.bucketName)
          .getPublicUrl(path);
    } catch (e) {
      logger.e('Error uploading image: $e');
      return null;
    }
  }
}
