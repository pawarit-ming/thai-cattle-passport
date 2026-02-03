import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/screens/cow_form/widgets/styled_text_field.dart';

class PhysicalInfoTab extends StatelessWidget {
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController colorController;
  final TextEditingController sireNameController;
  final TextEditingController sireIdController;
  final TextEditingController damNameController;
  final TextEditingController damIdController;

  const PhysicalInfoTab({
    super.key,
    required this.weightController,
    required this.heightController,
    required this.colorController,
    required this.sireNameController,
    required this.sireIdController,
    required this.damNameController,
    required this.damIdController,
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
                    keyboardType: TextInputType.number),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: StyledTextField(
                    label: 'ส่วนสูง (ซม.)',
                    hintText: 'เช่น 150',
                    controller: heightController,
                    icon: Icons.height,
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          StyledTextField(
            controller: colorController,
            label: 'สี',
            hintText: 'เช่น ขาว, ดำ, แดง',
            icon: Icons.color_lens,
          ),
          SizedBox(height: 16.h),
          StyledTextField(
              label: 'ชื่อพ่อพันธุ์',
              hintText: 'เช่น บราห์มัน',
              controller: sireNameController,
              icon: Icons.male),
          SizedBox(height: 16.h),
          StyledTextField(
              label: 'ID พ่อพันธุ์',
              hintText: 'Tag ID ของพ่อพันธุ์',
              controller: sireIdController,
              icon: Icons.male,
              keyboardType: TextInputType.number),
          SizedBox(height: 16.h),
          StyledTextField(
              label: 'ชื่อแม่พันธุ์',
              hintText: 'เช่น โลลิตา',
              controller: damNameController,
              icon: Icons.female),
          SizedBox(height: 16.h),
          StyledTextField(
              label: 'ID แม่พันธุ์',
              hintText: 'Tag ID ของแม่พันธุ์',
              controller: damIdController,
              icon: Icons.female,
              keyboardType: TextInputType.number),
        ],
      ),
    );
  }
}
