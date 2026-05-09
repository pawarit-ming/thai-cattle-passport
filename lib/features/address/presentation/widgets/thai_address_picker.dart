import 'package:flutter/material.dart';
import '../../data/datasources/thai_address_datasource.dart';
import '../../data/models/district_model.dart';
import '../../data/models/province_model.dart';
import '../../data/models/tambon_model.dart';
import 'package:th_cow_passport/ui/widgets/common/app_search_dropdown.dart';
import 'package:th_cow_passport/ui/widgets/common/app_text_field.dart';

class ThaiAddressPicker extends StatefulWidget {
  final Function(Province?, District?, Tambon?) onAddressChanged;
  final Province? initialProvince;
  final District? initialDistrict;
  final Tambon? initialTambon;

  const ThaiAddressPicker({
    super.key,
    required this.onAddressChanged,
    this.initialProvince,
    this.initialDistrict,
    this.initialTambon,
  });

  @override
  State<ThaiAddressPicker> createState() => ThaiAddressPickerState();
}

class ThaiAddressPickerState extends State<ThaiAddressPicker> {
  final ThaiAddressDatasource _datasource = ThaiAddressDatasource();

  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Tambon> _tambons = [];

  Province? _selectedProvince;
  District? _selectedDistrict;
  Tambon? _selectedTambon;

  final TextEditingController _zipCodeController = TextEditingController();

  /// True while the initial JSON data is being loaded from assets.
  bool _isLoading = true;

  /// True while [setAddressFromText] is running (autofill from map picker).
  bool _isAutofilling = false;

  @override
  void dispose() {
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _datasource.loadData();
    if (!mounted) return;
    setState(() {
      _provinces = _datasource.getProvinces();
      _isLoading = false;
    });
  }

  void _onProvinceChanged(Province? province) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null;
      _selectedTambon = null;
      _districts =
          province != null ? _datasource.getDistricts(province.id) : [];
      _tambons = [];
      _zipCodeController.text = '';
    });
    widget.onAddressChanged(
        _selectedProvince, _selectedDistrict, _selectedTambon);
  }

  void _onDistrictChanged(District? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedTambon = null;
      _tambons = district != null ? _datasource.getTambons(district.id) : [];
      _zipCodeController.text = '';
    });
    widget.onAddressChanged(
        _selectedProvince, _selectedDistrict, _selectedTambon);
  }

  void _onTambonChanged(Tambon? tambon) {
    setState(() {
      _selectedTambon = tambon;
      _zipCodeController.text = tambon?.zipCode.toString() ?? '';
    });
    widget.onAddressChanged(
        _selectedProvince, _selectedDistrict, _selectedTambon);
  }

  /// Autofill province / district / tambon from text strings returned by the
  /// map picker. Waits until the initial data load finishes before searching,
  /// eliminating the race condition where [_loadData] would reset selections.
  Future<void> setAddressFromText(
    String provinceName,
    String districtName,
    String tambonName,
    String zipCode,
  ) async {
    // Show loading overlay on the picker while we work.
    if (mounted) setState(() => _isAutofilling = true);

    try {
      // Wait for the initial data load to complete instead of re-loading data,
      // which would cause a race condition with the in-flight _loadData call.
      while (_isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }

      Province? p;
      District? d;
      Tambon? t;

      // 1. Try to find Province first
      if (provinceName.isNotEmpty) {
        final pLower = provinceName.toLowerCase();
        try {
          if (pLower == 'bangkok' ||
              pLower.contains('bangkok') ||
              provinceName.contains('กรุงเทพ') ||
              pLower.contains('krung thep')) {
            p = _provinces.firstWhere((e) =>
                e.nameEn.toLowerCase() == 'bangkok' ||
                e.nameTh.contains('กรุงเทพ'));
          } else {
            p = _provinces.firstWhere((e) {
              final nameTh = e.nameTh;
              final nameEn = e.nameEn.toLowerCase();
              return nameTh.contains(provinceName) ||
                  provinceName.contains(nameTh) ||
                  nameEn.contains(pLower) ||
                  pLower.contains(nameEn);
            });
          }
        } catch (_) {}
      }

      // 2. Try to find District and Tambon
      if (p != null) {
        final districts = _datasource.getDistricts(p.id);
        
        // Try match district by name
        if (districtName.isNotEmpty) {
          final dLower = districtName.toLowerCase();
          try {
            d = districts.firstWhere((e) {
              final nameTh = e.nameTh;
              final nameEn = e.nameEn.toLowerCase();
              return nameTh.contains(districtName) ||
                  districtName.contains(nameTh) ||
                  nameEn.contains(dLower) ||
                  dLower.contains(nameEn);
            });
          } catch (_) {}
        }

        if (d != null) {
          final tambons = _datasource.getTambons(d.id);
          // Try match tambon by name within district
          if (tambonName.isNotEmpty) {
            final tLower = tambonName.toLowerCase();
            try {
              t = tambons.firstWhere((e) {
                final nameTh = e.nameTh;
                final nameEn = e.nameEn.toLowerCase();
                return nameTh.contains(tambonName) ||
                    tambonName.contains(nameTh) ||
                    nameEn.contains(tLower) ||
                    tLower.contains(nameEn);
              });
            } catch (_) {}
          }
          
          // Fallback: match tambon by zip code within district
          if (t == null && zipCode.isNotEmpty) {
            try {
              t = tambons.firstWhere((e) => e.zipCode.toString() == zipCode);
            } catch (_) {}
          }
        }
      }

      // 3. ULTIMATE FALLBACK: If we still don't have a sub-district (T), 
      // search globally by zip code (very effective for Bangkok)
      if (t == null && zipCode.isNotEmpty) {
        try {
          // Search all tambons for this zip code

          // Let's use the internal _tambons list if possible, or search via province
          for (var prov in _provinces) {
            final dists = _datasource.getDistricts(prov.id);
            for (var dist in dists) {
              final tambs = _datasource.getTambons(dist.id);
              try {
                final found = tambs.firstWhere((e) => e.zipCode.toString() == zipCode);
                t = found;
                d = dist;
                p = prov;
                break;
              } catch (_) {}
            }
            if (t != null) break;
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (p != null) {
        final districts = _datasource.getDistricts(p.id);
        List<Tambon> tambons = [];
        if (d != null) {
          tambons = _datasource.getTambons(d.id);
        }
        
        setState(() {
          _selectedProvince = p;
          _selectedDistrict = d;
          _selectedTambon = t;
          _districts = districts;
          _tambons = tambons;
          _zipCodeController.text = t?.zipCode.toString() ?? zipCode;
        });
        widget.onAddressChanged(p, d, t);
      }
    } finally {
      if (mounted) setState(() => _isAutofilling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ));
    }

    // Show a subtle loading overlay while autofilling from map result.
    if (_isAutofilling) {
      return SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dimmed picker skeleton
            Opacity(
              opacity: 0.4,
              child: _buildPicker(),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'กำลังกรอกที่อยู่อัตโนมัติ...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _buildPicker();
  }

  Widget _buildPicker() {
    return Column(
      children: [
        AppSearchDropdown<Province>(
          label: 'จังหวัด',
          value: _selectedProvince,
          hintText: 'เลือกจังหวัด',
          items: _provinces
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.nameTh, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          itemAsString: (p) => p.nameTh,
          onChanged: _onProvinceChanged,
          isRequired: true,
          validator: (v) => v == null ? 'กรุณาเลือกจังหวัด' : null,
          prefixIcon: const Icon(Icons.map),
        ),
        AppSearchDropdown<District>(
          label: 'อำเภอ/เขต',
          value: _selectedDistrict,
          hintText: 'เลือกอำเภอ',
          items: _districts
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d.nameTh, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          itemAsString: (d) => d.nameTh,
          onChanged: _selectedProvince == null ? null : _onDistrictChanged,
          isRequired: true,
          validator: (v) => v == null ? 'กรุณาเลือกอำเภอ' : null,
          prefixIcon: const Icon(Icons.map),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSearchDropdown<Tambon>(
                label: 'ตำบล/แขวง',
                value: _selectedTambon,
                hintText: 'เลือกตำบล',
                items: _tambons
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child:
                              Text(t.nameTh, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                itemAsString: (t) => t.nameTh,
                onChanged: _districts.isEmpty ? null : _onTambonChanged,
                isRequired: true,
                validator: (v) => v == null ? 'กรุณาเลือกตำบล' : null,
                prefixIcon: const Icon(Icons.map),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                label: 'รหัสไปรษณีย์',
                controller: _zipCodeController,
                icon: Icons.markunread_mailbox,
                isRequired: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
