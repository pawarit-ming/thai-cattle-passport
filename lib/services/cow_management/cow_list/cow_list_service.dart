import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import '../../../supabase_config.dart';
import 'package:logger/logger.dart';

final cowServiceProvider = ChangeNotifierProvider((ref) => CowService());

class CowService extends ChangeNotifier {
  final logger = Logger();
  List<Cow> _cows = [];
  bool _isLoading = false;

  List<Cow> get cows => _cows;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch only my cows that are not soft-deleted
  Future<void> fetchCows({bool forceRefresh = false}) async {
    // 1. ดึง User ID ของผู้ใช้ที่ล็อกอินอยู่ปัจจุบัน
    final myUserId = supabase.auth.currentUser?.id;

    // ถ้าไม่ได้ล็อกอิน หรือหา ID ไม่เจอ ให้หยุดทำงาน (หรือเคลียร์ลิสต์)
    if (myUserId == null) {
      logger.w('User not logged in. Cannot fetch personal cows.');
      _cows = [];
      notifyListeners();
      return;
    }

    // Optimization: If we already have cows in memory and it's not a forced refresh, return immediately.
    if (_cows.isNotEmpty && !forceRefresh) {
      logger.d("Returning cows from memory (${_cows.length}).");
      return;
    }

    final cacheKey = 'cached_cows_$myUserId';

    // Try loading from cache first
    if (_cows.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          final List<dynamic> decodedList = jsonDecode(cachedData);
          _cows = decodedList.map((data) => Cow.fromMap(data)).toList();
          logger.d("Loaded ${_cows.length} cows from local cache.");
          notifyListeners();
        }
      } catch (e) {
        logger.e('Error loading from cache: $e', error: e);
      }
    }

    // If memory is still empty (no cache), show loading state
    bool silentlyFetch = _cows.isNotEmpty;
    if (!silentlyFetch) {
      _setLoading(true);
    }

    try {
      // --- ขั้นตอนที่ 1: ดึงวัวที่ฉันเป็นเจ้าของ ---
      final myCowsResponse = await supabase
          .from('animals')
          .select(
              'animal_id, user_id, farm_id, nid_number, animal_name, breed, sex, birth_date, color, weight, height, status, face_pic, body_pic, origin, import_date, created_at, updated_at')
          .eq('is_deleted', false)
          .eq('user_id', myUserId)
          .order('created_at', ascending: false);

      List<Cow> allCows =
          (myCowsResponse as List).map((data) => Cow.fromMap(data)).toList();

      // --- ขั้นตอนที่ 2: ดึงวัวที่ฉันรับฝากเลี้ยง (หาจากตาราง offers) ---
      // 2.1 หา ID วัวที่ฉันเคยขายและกดยอมรับไปแล้ว
      final myOffersResponse = await supabase
          .from('offers')
          .select('animal_id')
          .eq('seller_id', myUserId)
          .eq('status', 'accepted');

      final List<dynamic> offerList = myOffersResponse as List;

      if (offerList.isNotEmpty) {
        // ดึงเฉพาะ ID วัวออกมาเป็น List
        final List<int> soldAnimalIds =
            offerList.map((o) => int.parse(o['animal_id'].toString())).toList();

        // 2.2 ไปดึงข้อมูลวัวเหล่านั้นมา "เฉพาะตัวที่สถานะเป็น FOSTER"
        final fosteredCowsResponse = await supabase
            .from('animals')
            .select(
                'animal_id, user_id, farm_id, nid_number, animal_name, breed, sex, birth_date, color, weight, height, status, face_pic, body_pic, origin, import_date, created_at, updated_at')
            .eq('is_deleted', false)
            .eq('status', 'FOSTER')
            .filter('animal_id', 'in',
                soldAnimalIds); // ใช้ filter 'in' เพื่อค้นหาจาก List ID

        final List<Cow> fosteredCows = (fosteredCowsResponse as List)
            .map((data) => Cow.fromMap(data))
            .toList();

        // 2.3 นำวัวรับฝากเลี้ยง มารวมกับวัวของฉัน (เช็คไม่ให้ซ้ำ)
        for (var cow in fosteredCows) {
          if (!allCows.any((c) => c.animalId == cow.animalId)) {
            allCows.add(cow);
          }
        }
      }

      // เรียงลำดับทั้งหมดใหม่ตามวันที่สร้าง
      allCows.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.now();
        final dateB = b.createdAt ?? DateTime.now();
        return dateB.compareTo(dateA); // เรียงจากใหม่ไปเก่า
      });

      _cows = allCows;
      logger.d("Fetched ${_cows.length} cows in total for user: $myUserId");

      // Save to cache (โค้ดเดิมของคุณ)
      try {
        final prefs = await SharedPreferences.getInstance();
        final encodedData = jsonEncode(_cows.map((c) => c.toMap()).toList());
        await prefs.setString(cacheKey, encodedData);
      } catch (e) {
        logger.e('Error saving to cache: $e', error: e);
      }

      notifyListeners();
    } catch (e) {
      logger.e('Error fetching cows: $e', error: e);
    } finally {
      if (!silentlyFetch) {
        _setLoading(false);
      }
    }
  }

  // Soft delete a cow
  Future<void> deleteCow(int id) async {
    _setLoading(true);
    try {
      await supabase.from('animals').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('animal_id', id);

      // Remove the cow from the local list for immediate UI update
      _cows.removeWhere((cow) => cow.animalId == id);
      logger.i("Cow with ID $id soft-deleted successfully.");

      // Update cache
      try {
        final myUserId = supabase.auth.currentUser?.id;
        if (myUserId != null) {
          final prefs = await SharedPreferences.getInstance();
          final cacheKey = 'cached_cows_$myUserId';
          final encodedData = jsonEncode(_cows.map((c) => c.toMap()).toList());
          await prefs.setString(cacheKey, encodedData);
        }
      } catch (e) {
        logger.e('Error updating cache after delete: $e', error: e);
      }
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting cow: $e', error: e);
    } finally {
      _setLoading(false);
    }
  }
}
