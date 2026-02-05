import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/ui/screens/activity/widgets/form_widgets.dart';

// --- Abstract Base / Interface (Implicit in usage) ---

// --- Vaccine Form ---
class VaccineForm extends StatelessWidget {
  final TextEditingController nameController;

  const VaccineForm({super.key, required this.nameController});

  @override
  Widget build(BuildContext context) {
    return FormTextField(
      controller: nameController,
      labelText: 'ชื่อวัคซีน',
      hintText: 'เช่น วัคซีนป้องกันโรคปากและเท้าเปื่อย',
    );
  }
}

// --- Birth Form ---
class BirthForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController genderController;
  final TextEditingController nidController;
  final TextEditingController birthWeightController;

  // Sire Selection
  final String? sireType;
  final ValueChanged<String?> onSireTypeChanged;
  final List<dynamic> farmSires;
  final int? selectedSireId;
  final ValueChanged<int?> onSireIdChanged;
  final TextEditingController otherSireNameController;
  final TextEditingController otherSireOriginController;

  const BirthForm({
    super.key,
    required this.nameController,
    required this.genderController,
    required this.nidController,
    required this.birthWeightController,
    required this.sireType,
    required this.onSireTypeChanged,
    required this.farmSires,
    required this.selectedSireId,
    required this.onSireIdChanged,
    required this.otherSireNameController,
    required this.otherSireOriginController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormTextField(
          controller: nidController,
          labelText: 'เลขประจำตัวลูกวัว (NID)',
          hintText: 'กรอกเลข NID 13 หลัก',
          isRequired: true,
        ),
        SizedBox(height: 16.h),
        FormTextField(
          controller: nameController,
          labelText: 'ชื่อลูกวัว',
          hintText: 'ชื่อของลูกวัว',
        ),
        SizedBox(height: 16.h),
        // Gender Dropdown
        SizedBox(height: 16.h),
        // Gender Dropdown
        FormDropdownField<String>(
          label: 'เพศลูกวัว',
          isRequired: true,
          value: genderController.text.isEmpty ? null : genderController.text,
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('เพศผู้')),
            DropdownMenuItem(value: 'FEMALE', child: Text('เพศเมีย')),
          ],
          onChanged: (val) {
            if (val != null) {
              genderController.text = val;
            }
          },
        ),
        SizedBox(height: 16.h),
        // Sire Selection Section
        SizedBox(height: 16.h),
        FormDropdownField<String>(
          label: 'พ่อพันธุ์',
          isRequired: true,
          value: sireType,
          items: [
            DropdownMenuItem(value: 'FARM', child: Text('วัวในฟาร์ม')),
            const DropdownMenuItem(value: 'UNKNOWN', child: Text('ไม่ทราบ')),
            const DropdownMenuItem(value: 'OTHER', child: Text('อื่นๆ (ระบุ)')),
          ],
          onChanged: onSireTypeChanged,
        ),
        SizedBox(height: 16.h),

        if (sireType == 'FARM') ...[
          FormDropdownField<int>(
            label: 'เลือกพ่อพันธุ์ในฟาร์ม',
            isRequired: true,
            value: selectedSireId,
            hintText: farmSires.isEmpty ? 'ไม่มีพ่อพันธุ์ในฟาร์ม' : 'เลือกวัว',
            items: farmSires.map((cow) {
              return DropdownMenuItem<int>(
                value: cow.animalId,
                child: Text('${cow.animalName} (${cow.nidNumber})'),
              );
            }).toList(),
            onChanged: onSireIdChanged,
          ),
          SizedBox(height: 16.h),
        ] else if (sireType == 'OTHER') ...[
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลพ่อพันธุ์ภายนอก',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                FormTextField(
                  controller: otherSireNameController,
                  labelText: 'ชื่อพ่อพันธุ์',
                  hintText: 'ระบุชื่อพ่อพันธุ์',
                  isRequired: true,
                ),
                SizedBox(height: 12.h),
                FormTextField(
                  controller: otherSireOriginController,
                  labelText: 'ที่มา / สังกัด',
                  hintText: 'เช่น ศูนย์วิจัยฯ, ฟาร์มข้างเคียง',
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],

        FormTextField(
          controller: birthWeightController,
          labelText: 'น้ำหนักแรกเกิด (กก.)',
          hintText: 'เช่น 25.5',
          isRequired: false,
        ),
      ],
    );
  }
}

// --- Treatment Form ---
class TreatmentForm extends StatelessWidget {
  final TextEditingController symptomsController;
  final TextEditingController treatmentDetailsController;

  const TreatmentForm({
    super.key,
    required this.symptomsController,
    required this.treatmentDetailsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormTextField(
          controller: symptomsController,
          labelText: 'อาการ',
          maxLines: 3,
          hintText: 'อธิบายอาการป่วยของวัว',
        ),
        SizedBox(height: 16.h),
        FormTextField(
          controller: treatmentDetailsController,
          labelText: 'รายละเอียดการรักษา',
          maxLines: 3,
          hintText: 'ระบุยาและวิธีการรักษา',
        ),
      ],
    );
  }
}

// --- Weight Form ---
class WeightForm extends StatelessWidget {
  final TextEditingController weightController;

  const WeightForm({super.key, required this.weightController});

  @override
  Widget build(BuildContext context) {
    return FormTextField(
      controller: weightController,
      labelText: 'น้ำหนักปัจจุบัน (กก.)',
      hintText: 'เช่น 450.5',
    );
  }
}

// --- Breeding Form ---
class BreedingForm extends StatelessWidget {
  final String? breedingMethod;
  final ValueChanged<String?> onMethodChanged;

  final String partnerLabel; // Label for Sire/Dam (พ่อพันธุ์/แม่พันธุ์)
  final String? sireType;
  final ValueChanged<String?> onSireTypeChanged;

  final List<dynamic> farmSires; // List<Cow>
  final int? selectedSireId;
  final ValueChanged<int?> onSireIdChanged;

  final TextEditingController otherSireNameController;
  final TextEditingController otherSireOriginController;

  const BreedingForm({
    super.key,
    required this.breedingMethod,
    required this.onMethodChanged,
    required this.partnerLabel,
    required this.sireType,
    required this.onSireTypeChanged,
    required this.farmSires,
    required this.selectedSireId,
    required this.onSireIdChanged,
    required this.otherSireNameController,
    required this.otherSireOriginController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Breeding Method
        FormDropdownField<String>(
          label: 'วิธีการ',
          isRequired: true,
          value: breedingMethod,
          items: const [
            DropdownMenuItem(value: 'NATURAL', child: Text('ตามธรรมชาติ')),
            DropdownMenuItem(value: 'AI', child: Text('ผสมเทียม')),
          ],
          onChanged: onMethodChanged,
        ),
        SizedBox(height: 16.h),

        // 2. Sire Source (Type)
        FormDropdownField<String>(
          label: partnerLabel, // Use dynamic label
          isRequired: true,
          value: sireType,
          items: [
            DropdownMenuItem(value: 'FARM', child: Text('วัวในฟาร์ม')),
            const DropdownMenuItem(value: 'UNKNOWN', child: Text('ไม่ทราบ')),
            const DropdownMenuItem(value: 'OTHER', child: Text('อื่นๆ (ระบุ)')),
          ],
          onChanged: onSireTypeChanged,
        ),
        SizedBox(height: 16.h),

        // 3. Conditional Inputs
        if (sireType == 'FARM') ...[
          FormDropdownField<int>(
            label: 'เลือก$partnerLabelในฟาร์ม',
            isRequired: true,
            value: selectedSireId,
            hintText:
                farmSires.isEmpty ? 'ไม่มี$partnerLabelในฟาร์ม' : 'เลือกวัว',
            items: farmSires.map((cow) {
              return DropdownMenuItem<int>(
                value: cow.animalId,
                child: Text('${cow.animalName} (${cow.nidNumber})'),
              );
            }).toList(),
            onChanged: onSireIdChanged,
          ),
        ] else if (sireType == 'OTHER') ...[
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูล$partnerLabelภายนอก',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                FormTextField(
                  controller: otherSireNameController,
                  labelText: 'ชื่อ$partnerLabel',
                  hintText: 'ระบุชื่อ$partnerLabel',
                  isRequired: true,
                ),
                SizedBox(height: 12.h),
                FormTextField(
                  controller: otherSireOriginController,
                  labelText: 'ที่มา / สังกัด',
                  hintText: 'เช่น ศูนย์วิจัยฯ, ฟาร์มข้างเคียง',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PregnancyCheckForm extends StatelessWidget {
  final String? checkMethod;
  final ValueChanged<String?> onMethodChanged;
  final String? checkResult;
  final ValueChanged<String?> onResultChanged;
  final TextEditingController weeksController;
  final TextEditingController daysController;

  const PregnancyCheckForm({
    super.key,
    required this.checkMethod,
    required this.onMethodChanged,
    required this.checkResult,
    required this.onResultChanged,
    required this.weeksController,
    required this.daysController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Check Method
        FormDropdownField<String>(
          label: 'วิธีการตรวจ',
          isRequired: true,
          value: checkMethod,
          items: const [
            DropdownMenuItem(value: 'PALPATION', child: Text('การคลำ')),
            DropdownMenuItem(value: 'ULTRASOUND', child: Text('อัลตร้าซาวด์')),
            DropdownMenuItem(value: 'OBSERVATION', child: Text('การสังเกต')),
            DropdownMenuItem(value: 'BLOOD', child: Text('เจาะเลือด')),
            DropdownMenuItem(value: 'URINE', child: Text('ตรวจปัสสาวะ')),
          ],
          onChanged: onMethodChanged,
        ),
        SizedBox(height: 16.h),

        // 2. Check Result
        FormDropdownField<String>(
          label: 'ผลการตรวจ',
          isRequired: true,
          value: checkResult,
          items: const [
            DropdownMenuItem(value: 'PREGNANT', child: Text('ตั้งครรภ์')),
            DropdownMenuItem(
                value: 'NOT_PREGNANT', child: Text('ไม่ตั้งครรภ์')),
            DropdownMenuItem(
                value: 'RECHECK', child: Text('ตรวจใหม่/ไม่แน่ใจ')),
          ],
          onChanged: onResultChanged,
        ),
        SizedBox(height: 16.h),

        // 3. Conditional: Age if Pregnant
        if (checkResult == 'PREGNANT') ...[
          // Header Label
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Text('อายุครรภ์',
                    style: Theme.of(context).textTheme.labelLarge),
                const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormTextField(
                    controller: weeksController,
                    labelText: 'สัปดาห์',
                    hintText: '0',
                    isRequired: false,
                    keyboardType: TextInputType.number,
                    suffixText: 'สัปดาห์',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FormTextField(
                    controller: daysController,
                    labelText: 'วัน',
                    hintText: '0',
                    isRequired: false,
                    keyboardType: TextInputType.number,
                    suffixText: 'วัน',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --- Generic Form (for Breeding, Death, Sold, etc.) ---
class GenericForm extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const GenericForm({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FormTextField(
      controller: controller,
      labelText: label,
      maxLines: 5,
    );
  }
}
