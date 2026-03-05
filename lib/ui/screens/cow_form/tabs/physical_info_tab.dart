import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:th_cow_passport/core/constants/animal_constants.dart';
import 'package:flutter/services.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';
import 'package:th_cow_passport/ui/widgets/cow_selection_field.dart';
import 'package:th_cow_passport/ui/widgets/common/app_search_dropdown.dart';

class PhysicalInfoTab extends StatefulWidget {
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController colorController;
  final int? selectedSireId;
  final int? selectedDamId;
  final Function(Cow?) onSireSelected;
  final Function(Cow?) onDamSelected;

  const PhysicalInfoTab({
    super.key,
    required this.weightController,
    required this.heightController,
    required this.colorController,
    this.selectedSireId,
    this.selectedDamId,
    required this.onSireSelected,
    required this.onDamSelected,
  });

  @override
  State<PhysicalInfoTab> createState() => _PhysicalInfoTabState();
}

class _PhysicalInfoTabState extends State<PhysicalInfoTab> {
  // State
  String? _selectedColor;
  final TextEditingController _customColorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeColorFields();
  }

  void _initializeColorFields() {
    final currentColor = widget.colorController.text;
    if (currentColor.isNotEmpty) {
      if (AnimalConstants.colorOptions.contains(currentColor)) {
        _selectedColor = currentColor;
      } else {
        _selectedColor = AnimalConstants.customOption;
        _customColorController.text = currentColor;
      }
    } else {
      _selectedColor = null;
    }

    // Listen to custom controller to update main controller
    _customColorController.addListener(() {
      if (_selectedColor == AnimalConstants.customOption) {
        widget.colorController.text = _customColorController.text;
      }
    });
  }

  @override
  void dispose() {
    _customColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StyledTextField(
                  label: 'น้ำหนัก (กก.)',
                  hintText: 'เช่น 450.5',
                  controller: widget.weightController,
                  icon: Icons.monitor_weight,
                  suffixText: 'กก.',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,4}(\.\d{0,2})?')),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: StyledTextField(
                  label: 'ส่วนสูง (ซม.)',
                  hintText: 'เช่น 150',
                  controller: widget.heightController,
                  icon: Icons.height,
                  suffixText: 'ซม.',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,4}(\.\d{0,2})?')),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          AppSearchDropdown<String>(
            label: 'สี',
            value: _selectedColor,
            hintText: 'เลือกสี',
            prefixIcon: const Icon(Icons.color_lens),
            items: AnimalConstants.colorOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            itemAsString: (color) => color,
            onChanged: (newValue) {
              setState(() {
                _selectedColor = newValue;
                if (newValue == AnimalConstants.customOption) {
                  widget.colorController.text = _customColorController.text;
                } else {
                  widget.colorController.text = newValue ?? '';
                }
              });
            },
          ),
          if (_selectedColor == AnimalConstants.customOption) ...[
            SizedBox(height: 16.h),
            StyledTextField(
              label: 'ระบุสี',
              controller: _customColorController,
              icon: Icons.palette,
              hintText: 'เช่น เหลืองอ่อน, ส้มแดง',
              isRequired: true,
            ),
          ],
          SizedBox(height: 16.h),
          CowSelectionField(
            label: 'พ่อพันธุ์',
            icon: Icons.male,
            initialCowId: widget.selectedSireId,
            onCowSelected: widget.onSireSelected,
          ),
          SizedBox(height: 16.h),
          CowSelectionField(
            label: 'แม่พันธุ์',
            icon: Icons.female,
            initialCowId: widget.selectedDamId,
            onCowSelected: widget.onDamSelected,
          ),
        ],
      ),
    );
  }
}
