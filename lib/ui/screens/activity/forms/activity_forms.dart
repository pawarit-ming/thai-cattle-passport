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
  final TextEditingController breedController;
  final TextEditingController nidController;
  final TextEditingController birthWeightController;

  const BirthForm({
    super.key,
    required this.nameController,
    required this.genderController,
    required this.breedController,
    required this.nidController,
    required this.birthWeightController,
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
        // Breed Dropdown
        FormDropdownField<String>(
          label: 'พันธุ์ลูกวัว',
          isRequired: true,
          value: breedController.text.isEmpty ? null : breedController.text,
          items: [
            'บราห์มัน',
            'ชาร์โรเลส์',
            'วากิว',
            'แองกัส',
            'ฮินดูบราซิล',
            'พื้นเมือง',
            'อื่นๆ'
          ]
              .map(
                  (breed) => DropdownMenuItem(value: breed, child: Text(breed)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              breedController.text = val;
            }
          },
        ),
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

// --- Generic Form (for Breeding, Death, Sold, etc.) ---
class GenericForm extends StatelessWidget {
  final TextEditingController
      controller; // Using generic controller passed down
  final String label;

  const GenericForm({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Note: The original generic form reused the 'description' controller.
    // Here we assume the parent might pass a specific one or the description one.
    // If it's just a description, we might not even need this field if the 'Note' field covers it,
    // but the original had a specific field for it separate from 'Note'.
    // We'll keep it as a text field.
    return FormTextField(
      controller: controller,
      labelText: label,
      maxLines: 5,
    );
  }
}
