import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import '../../../supabase_config.dart';
import 'package:logger/logger.dart';

final cowDetailServiceProvider = ChangeNotifierProvider((ref) => CowDetailService());

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
  Future<bool> updateCow(Cow updatedCow, {File? newFacePic, File? newBodyPic, File? newMarkPic}) async {
    _setLoading(true);
    try {
      String? faceUrl = updatedCow.facePic;
      String? bodyUrl = updatedCow.fullBodyPic;
      String? markUrl = updatedCow.markPic;

      // ถ้ามีการเลือกรูปใหม่ ให้ทำการอัปโหลดก่อน
      if (newFacePic != null) faceUrl = await _uploadImage(newFacePic, updatedCow.nidNumber, 'face');
      if (newBodyPic != null) bodyUrl = await _uploadImage(newBodyPic, updatedCow.nidNumber, 'body');
      if (newMarkPic != null) markUrl = await _uploadImage(newMarkPic, updatedCow.nidNumber, 'mark');

      final dataToUpdate = {
        'animal_name': updatedCow.animalName,
        'nid_number': updatedCow.nidNumber,
        'breed': updatedCow.breed,
        'animal_color': updatedCow.animalColor,
        'weight': updatedCow.weight,
        'height': updatedCow.height,
        'eye_color': updatedCow.eyeColor,
        'nose_color': updatedCow.noseColor,
        'dam_id': updatedCow.damId,
        'sire_id': updatedCow.sireId,
        'mark_number': updatedCow.markNumber,
        'birth_date': updatedCow.birthDate?.toIso8601String(),
        'sex': updatedCow.sex,
        'animal_status': updatedCow.animalStatus,
        'face_pic': faceUrl,
        'full_body_pic': bodyUrl,
        'mark_pic': markUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('animals')
          .update(dataToUpdate)
          .eq('animal_id', updatedCow.animalId!);

      _currentCow = updatedCow; // อัปเดต State ในแอป
      logger.i("Cow updated successfully: ${updatedCow.animalName}");
      return true;
    } catch (e) {
      logger.e('Error updating cow: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 3. ฟังก์ชันเพิ่มวัวใหม่ (Add)
  Future<bool> addCow(Cow cow, {File? fullBodyPic, File? facePic, File? markPic}) async {
    _setLoading(true);
    try {
      String? fullBodyPicUrl;
      String? facePicUrl;
      String? markPicUrl;

      // Upload images if provided, using the typed _uploadImage method
      if (fullBodyPic != null) {
        fullBodyPicUrl = await _uploadImage(fullBodyPic, cow.nidNumber, 'body');
      }
      if (facePic != null) {
        facePicUrl = await _uploadImage(facePic, cow.nidNumber, 'face');
      }
      if (markPic != null) {
        markPicUrl = await _uploadImage(markPic, cow.nidNumber, 'mark');
      }

      final cowWithImages = cow.copyWith(
        fullBodyPic: fullBodyPicUrl,
        facePic: facePicUrl,
        markPic: markPicUrl,
      );

      // Assuming the model has a method to convert to a map suitable for insertion
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
  Future<String?> _uploadImage(File imageFile, String cowNid, String type) async {
    try {
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final String path = '${SupabaseConfig.bucketName}/$cowNid/$fileName';

      await supabase.storage.from(SupabaseConfig.bucketName).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(path);
    } catch (e) {
      logger.e('Error uploading image: $e');
      return null;
    }
  }
}