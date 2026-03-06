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
  State<ThaiAddressPicker> createState() => _ThaiAddressPickerState();
}

class _ThaiAddressPickerState extends State<ThaiAddressPicker> {
  final ThaiAddressDatasource _datasource = ThaiAddressDatasource();

  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Tambon> _tambons = [];

  Province? _selectedProvince;
  District? _selectedDistrict;
  Tambon? _selectedTambon;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _datasource.loadData();
    setState(() {
      _provinces = _datasource.getProvinces();
      _isLoading = false;

      // Handle initial values if provided (simple logic, assume IDs match)
      // Ideally we should match by ID, but references might differ.
      // For now, we rely on user selection flow.
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
    });
    widget.onAddressChanged(
        _selectedProvince, _selectedDistrict, _selectedTambon);
  }

  void _onDistrictChanged(District? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedTambon = null;
      _tambons = district != null ? _datasource.getTambons(district.id) : [];
    });
    widget.onAddressChanged(
        _selectedProvince, _selectedDistrict, _selectedTambon);
  }

  void _onTambonChanged(Tambon? tambon) {
    setState(() {
      _selectedTambon = tambon;
    });
    widget.onAddressChanged(
        _selectedProvince, _selectedDistrict, _selectedTambon);
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
          validator: (v) => v == null ? 'กรุณาเลือกจังหวัด' : null,
          prefixIcon: const Icon(Icons.map),
        ),
        const SizedBox(height: 16),
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
          onChanged: _selectedProvince == null
              ? null
              : _onDistrictChanged, // Disable if no province
          validator: (v) => v == null ? 'กรุณาเลือกอำเภอ' : null,
          prefixIcon: const Icon(Icons.map),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align top for different heights
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
                validator: (v) => v == null ? 'กรุณาเลือกตำบล' : null,
                prefixIcon: const Icon(Icons.map),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                label: 'รหัสไปรษณีย์',
                controller: TextEditingController(
                    text: _selectedTambon?.zipCode.toString() ?? ''),
                icon: Icons.markunread_mailbox,
                // Read-only essentially, but using StyledTextField for consistency
                // We might need to modify StyledTextField to support readOnly if not present
              ),
            ),
          ],
        ),
      ],
    );
  }
}
