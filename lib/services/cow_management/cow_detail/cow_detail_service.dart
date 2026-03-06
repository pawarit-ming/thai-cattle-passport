import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import '../../../supabase_config.dart';
import 'package:logger/logger.dart';

final cowDetailServiceProvider =
    ChangeNotifierProvider((ref) => CowDetailService());

final offspringProvider =
    FutureProvider.family<List<Cow>, int>((ref, cowId) async {
  final service = ref.watch(cowDetailServiceProvider);
  return service.getOffspring(cowId);
});

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
    final cacheKey = 'cached_cow_detail_$id';
    bool silentlyFetch = false;

    // Load from cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        _currentCow = Cow.fromMap(jsonDecode(cachedData));
        silentlyFetch = true;
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error loading cow detail from cache: $e');
    }

    if (!silentlyFetch) {
      _setLoading(true);
    }

    try {
      final response = await supabase
          .from('animals')
          .select()
          .eq('animal_id', id)
          .single(); // ดึงมาแค่แถวเดียว

      _currentCow = Cow.fromMap(response);
      logger.d("Fetched detail for cow: ${_currentCow?.animalName}");

      // Save to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(_currentCow!.toMap()));
      } catch (e) {
        logger.e('Error saving cow detail to cache: $e');
      }

      notifyListeners();
    } catch (e) {
      logger.e('Error fetching cow detail: $e');
    } finally {
      if (!silentlyFetch) {
        _setLoading(false);
      }
    }
  }

  // 2. ฟังก์ชันแก้ไขข้อมูลวัว (Update)
  Future<String?> updateCow(Cow updatedCow,
      {List<File>? newFaceFiles, List<File>? newBodyFiles}) async {
    _setLoading(true);
    try {
      // Prepare lists (initially from the model, or empty if null)
      List<String> faceUrls = List.from(updatedCow.facePic ?? []);
      List<String> bodyUrls = List.from(updatedCow.bodyPic ?? []);

      final nidNumber = updatedCow.nidNumber;

      // Upload new images and APPEND to the list
      if (newFaceFiles != null) {
        for (final file in newFaceFiles) {
          final url = await _uploadImage(file, nidNumber, 'face');
          if (url != null) {
            faceUrls.add(url);
          }
        }
      }
      if (newBodyFiles != null) {
        for (final file in newBodyFiles) {
          final url = await _uploadImage(file, nidNumber, 'body');
          if (url != null) {
            bodyUrls.add(url);
          }
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
        'sire_id': updatedCow.sireId,
        'birth_date': updatedCow.birthDate?.toIso8601String(),
        'sex': updatedCow.sex,
        'status': updatedCow.status,
        'face_pic': faceUrls,
        'body_pic': bodyUrls,
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
      // Clear detail cache to ensure fresh data loads next time
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_cow_detail_${updatedCow.animalId}');
      } catch (_) {}

      _setLoading(false);
    }
  }

  // 3. ฟังก์ชันเพิ่มวัวใหม่ (Add)
  Future<bool> addCow(Cow cow, {File? bodyPic, File? facePic}) async {
    _setLoading(true);
    try {
      List<String>? bodyPicUrls;
      List<String>? facePicUrls;
      final nidNumber = cow.nidNumber;

      // Upload images if provided
      if (bodyPic != null) {
        final url = await _uploadImage(bodyPic, nidNumber, 'body');
        if (url != null) bodyPicUrls = [url];
      }
      if (facePic != null) {
        final url = await _uploadImage(facePic, nidNumber, 'face');
        if (url != null) facePicUrls = [url];
      }

      final cowWithImages = cow.copyWith(
        bodyPic: bodyPicUrls,
        facePic: facePicUrls,
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

  // 4. Fetch offspring (ลูกโค)
  Future<List<Cow>> getOffspring(int cowId) async {
    try {
      final response = await supabase
          .from('animals')
          .select()
          .or('dam_id.eq.$cowId,sire_id.eq.$cowId')
          .filter('is_deleted', 'eq', false) // Exclude deleted cows
          .order('birth_date', ascending: false);

      if (response.isEmpty) {
        return [];
      }
      return (response as List).map((item) => Cow.fromMap(item)).toList();
    } catch (e) {
      logger.e('Error fetching offspring: $e');
      throw Exception('ไม่สามารถดึงข้อมูลลูกโคได้');
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
