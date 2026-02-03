import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialGender;
  final List<String> initialBreeds;
  final RangeValues initialAgeRange;
  final RangeValues initialWeightRange;
  final List<String> availableBreeds;
  final Function(
    String? gender,
    List<String> breeds,
    RangeValues ageRange,
    RangeValues weightRange,
  ) onApply;

  const FilterBottomSheet({
    super.key,
    this.initialGender,
    required this.initialBreeds,
    required this.initialAgeRange,
    required this.initialWeightRange,
    required this.availableBreeds,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _selectedGender;
  late List<String> _selectedBreeds;
  late RangeValues _ageRange;
  late RangeValues _weightRange;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
    _selectedBreeds = List.from(widget.initialBreeds);
    _ageRange = widget.initialAgeRange;
    _weightRange = widget.initialWeightRange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'กรองข้อมูลวัว',
            style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView(
              children: [
                _buildFilterSectionHeader('เพศ', theme),
                Row(
                  children: [
                    _buildGenderChip('ตัวผู้', 'MALE', theme),
                    SizedBox(width: 10.w),
                    _buildGenderChip('ตัวเมีย', 'FEMALE', theme),
                  ],
                ),
                SizedBox(height: 24.h),
                _buildFilterSectionHeader('สายพันธุ์', theme),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: widget.availableBreeds.map((breed) {
                    final isSelected = _selectedBreeds.contains(breed);
                    return FilterChip(
                      label: Text(breed),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      disabledColor: theme.cardColor,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      backgroundColor: theme.cardColor,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : theme.dividerColor,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedBreeds.add(breed);
                          } else {
                            _selectedBreeds.remove(breed);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
                _buildFilterSectionHeader(
                    'อายุ (${_ageRange.start.round()} - ${_ageRange.end.round()} ปี)',
                    theme),
                RangeSlider(
                  activeColor: colorScheme.primary,
                  inactiveColor: theme.scaffoldBackgroundColor,
                  values: _ageRange,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  labels: RangeLabels(
                      '${_ageRange.start.round()}', '${_ageRange.end.round()}'),
                  onChanged: (val) => setState(() => _ageRange = val),
                ),
                _buildFilterSectionHeader(
                    'น้ำหนัก (${_weightRange.start.round()} - ${_weightRange.end.round()} กก.)',
                    theme),
                RangeSlider(
                  activeColor: colorScheme.primary,
                  inactiveColor: theme.scaffoldBackgroundColor,
                  values: _weightRange,
                  min: 0,
                  max: 1500,
                  divisions: 150,
                  labels: RangeLabels('${_weightRange.start.round()}',
                      '${_weightRange.end.round()}'),
                  onChanged: (val) => setState(() => _weightRange = val),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedGender = null;
                      _selectedBreeds.clear();
                      _ageRange = const RangeValues(0, 20);
                      _weightRange = const RangeValues(0, 1500);
                    });
                  },
                  child: const Text('ล้างค่า'),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedGender, _selectedBreeds, _ageRange,
                        _weightRange);
                    Navigator.pop(context);
                  },
                  child: const Text('ค้นหา'),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
    );
  }

  Widget _buildGenderChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedGender == value;
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      disabledColor: theme.cardColor,
      labelStyle:
          TextStyle(color: isSelected ? colorScheme.onPrimary : Colors.black),
      backgroundColor: theme.cardColor,
      side: BorderSide(
          color: isSelected ? Colors.transparent : theme.dividerColor),
      onSelected: (bool selected) {
        setState(() {
          _selectedGender = selected ? value : null;
        });
      },
    );
  }
}
