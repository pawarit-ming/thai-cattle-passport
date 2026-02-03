import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/province_model.dart';
import '../models/district_model.dart';
import '../models/tambon_model.dart';

class ThaiAddressDatasource {
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Tambon> _tambons = [];

  Future<void> loadData() async {
    if (_provinces.isNotEmpty) return;

    final provincesJson =
        await rootBundle.loadString('assets/data/thai_provinces.json');
    final districtsJson =
        await rootBundle.loadString('assets/data/thai_districts.json');
    final tambonsJson =
        await rootBundle.loadString('assets/data/thai_tambons.json');

    final List<dynamic> provincesList = json.decode(provincesJson);
    final List<dynamic> districtsList = json.decode(districtsJson);
    final List<dynamic> tambonsList = json.decode(tambonsJson);

    _provinces = provincesList.map((e) => Province.fromJson(e)).toList();
    _districts = districtsList.map((e) => District.fromJson(e)).toList();
    _tambons = tambonsList.map((e) => Tambon.fromJson(e)).toList();

    // Sort by name for better UX
    _provinces.sort((a, b) => a.nameTh.compareTo(b.nameTh));
    _districts.sort((a, b) => a.nameTh.compareTo(b.nameTh));
    _tambons.sort((a, b) => a.nameTh.compareTo(b.nameTh));
  }

  List<Province> getProvinces() => _provinces;

  List<District> getDistricts(int provinceId) {
    return _districts.where((e) => e.provinceId == provinceId).toList();
  }

  List<Tambon> getTambons(int districtId) {
    return _tambons.where((e) => e.districtId == districtId).toList();
  }

  Tambon? getTambonById(int id) {
    try {
      return _tambons.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
