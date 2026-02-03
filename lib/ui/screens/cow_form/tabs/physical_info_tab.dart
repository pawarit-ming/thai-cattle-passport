import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/models/cow_model.dart';
import 'package:th_cow_passport/ui/widgets/styled_text_field.dart';
import 'package:th_cow_passport/ui/widgets/cow_selection_field.dart';

class PhysicalInfoTab extends StatelessWidget {
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
                    controller: weightController,
                    icon: Icons.monitor_weight,
                    suffixText: 'กก.',
                    keyboardType: TextInputType.number),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: StyledTextField(
                    label: 'ส่วนสูง (ซม.)',
                    hintText: 'เช่น 150',
                    controller: heightController,
                    icon: Icons.height,
                    suffixText: 'ซม.',
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Color Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สี', style: Theme.of(context).textTheme.labelLarge),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                initialValue: colorController.text.isNotEmpty &&
                        ['ขาว', 'ดำ', 'แดง', 'น้ำตาล', 'ด่าง', 'อื่น']
                            .contains(colorController.text)
                    ? colorController.text
                    : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.color_lens),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                hint: const Text('เลือกสี'),
                items: ['ขาว', 'ดำ', 'แดง', 'น้ำตาล', 'ด่าง', 'อื่น']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    colorController.text = newValue;
                  }
                },
              ),
            ],
          ),

          SizedBox(height: 16.h),

          CowSelectionField(
            label: 'พ่อพันธุ์',
            icon: Icons.male,
            initialCowId: selectedSireId,
            onCowSelected: onSireSelected,
          ),
          SizedBox(height: 16.h),
          CowSelectionField(
            label: 'แม่พันธุ์',
            icon: Icons.female,
            initialCowId: selectedDamId,
            onCowSelected: onDamSelected,
          ),
        ],
      ),
    );
  }
}
