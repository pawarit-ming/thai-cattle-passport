import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:th_cow_passport/services/cow_management/models/vaccine_model.dart';
import 'package:th_cow_passport/ui/screens/activity/widgets/form_widgets.dart';

// --- Abstract Base / Interface (Implicit in usage) ---

// --- Vaccine Form ---
class VaccineForm extends StatelessWidget {
  final List<dynamic> vaccines;
  final String? selectedVaccineId;
  final int? selectedDoseNumber;
  final TextEditingController noteController;
  final ValueChanged<String?> onVaccineChanged;
  final ValueChanged<int?> onDoseChanged;
  final Map<String, List<Map<String, dynamic>>> vaccineHistory;
  final String? cowSex; // 'MALE' or 'FEMALE'

  const VaccineForm({
    super.key,
    required this.vaccines,
    required this.selectedVaccineId,
    required this.selectedDoseNumber,
    required this.noteController,
    required this.onVaccineChanged,
    required this.onDoseChanged,
    this.vaccineHistory = const {},
    this.cowSex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Find selected vaccine object
    Vaccine? selectedVaccine;
    if (selectedVaccineId != null) {
      try {
        selectedVaccine =
            vaccines.firstWhere((v) => (v as Vaccine).id == selectedVaccineId)
                as Vaccine;
      } catch (_) {
        selectedVaccine = null;
      }
    }

    // Get completed doses for the selected vaccine
    final completedDoses = selectedVaccineId != null
        ? (vaccineHistory[selectedVaccineId] ?? [])
        : <Map<String, dynamic>>[];
    final completedDoseNumbers =
        completedDoses.map((d) => d['dose_number'] as int).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Vaccine Selection ---
        Text(
          'เลือกวัคซีน *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        ...vaccines.where((vaccine) {
          // Filter by gender
          final v = vaccine as Vaccine;
          if (v.genderFilter == null) return true;
          return v.genderFilter == cowSex;
        }).map((vaccine) {
          final v = vaccine as Vaccine;
          final isSelected = v.id == selectedVaccineId;
          final history = vaccineHistory[v.id] ?? [];
          final givenCount = history.length;
          final allDone = givenCount >= v.totalDoses;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: InkWell(
              onTap: () {
                onVaccineChanged(v.id);
                // Auto-select next available dose
                final givenNums =
                    history.map((d) => d['dose_number'] as int).toSet();
                int? nextDose;
                for (int i = 1; i <= v.totalDoses; i++) {
                  if (!givenNums.contains(i)) {
                    nextDose = i;
                    break;
                  }
                }
                onDoseChanged(nextDose);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio-like indicator
                    Container(
                      width: 20.r,
                      height: 20.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 14.r, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    // Vaccine info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.nameTh,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            v.nameEn,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dose progress badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: allDone
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        allDone ? '✅ ครบ' : '$givenCount/${v.totalDoses} เข็ม',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: allDone
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          fontWeight:
                              allDone ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // --- Dose Selection with history ---
        if (selectedVaccine != null) ...[
          SizedBox(height: 16.h),
          Text(
            'เข็มที่ *',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          // Dose timeline
          ...selectedVaccine.doseOptions.map((doseNum) {
            final isDone = completedDoseNumbers.contains(doseNum);
            final isCurrentlySelected = selectedDoseNumber == doseNum;
            String? doneDate;
            if (isDone) {
              final record =
                  completedDoses.firstWhere((d) => d['dose_number'] == doseNum);
              final dateStr = record['activity_date']?.toString();
              if (dateStr != null) {
                final dt = DateTime.tryParse(dateStr);
                if (dt != null) {
                  doneDate = '${dt.day}/${dt.month}/${dt.year + 543}';
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: InkWell(
                onTap: isDone ? null : () => onDoseChanged(doseNum),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.grey.shade100
                        : isCurrentlySelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDone
                          ? Colors.grey.shade300
                          : isCurrentlySelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                      width: isCurrentlySelected && !isDone ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle
                            : isCurrentlySelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                        size: 20.r,
                        color: isDone
                            ? Colors.green
                            : isCurrentlySelected
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          selectedVaccine!.getDoseLabel(doseNum),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: isCurrentlySelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color:
                                isDone ? Colors.grey.shade500 : Colors.black87,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isDone && doneDate != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '✅ $doneDate',
                            style: TextStyle(
                                fontSize: 10.sp, color: Colors.green.shade700),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // All-done banner
          if (completedDoseNumbers.length >= selectedVaccine.totalDoses) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16.r, color: Colors.green.shade700),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'วัคซีนนี้ฉีดครบทุกเข็มแล้ว',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        // Note (if vaccine has one)
        if (selectedVaccine != null && selectedVaccine.note != null) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16.r, color: Colors.amber.shade700),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    selectedVaccine.note!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // --- Note ---
        SizedBox(height: 16.h),
        FormTextField(
          controller: noteController,
          labelText: 'หมายเหตุ',
          hintText: 'เพิ่มเติม (ถ้ามี)',
          isRequired: false,
          maxLines: 2,
        ),
      ],
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
          assetIcon: 'assets/images/calf.png',
        ),
        SizedBox(height: 16.h),
        // Gender Dropdown
        SizedBox(height: 16.h),
        // Gender Dropdown
        FormDropdownField<String>(
          label: 'เพศลูกวัว',
          isRequired: true,
          value: genderController.text.isEmpty ? null : genderController.text,
          assetIcon: 'assets/images/gender.png',
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

// --- Illness Form ---
class IllnessForm extends StatelessWidget {
  final TextEditingController symptomsController;

  const IllnessForm({super.key, required this.symptomsController});

  @override
  Widget build(BuildContext context) {
    return FormTextField(
      controller: symptomsController,
      labelText: 'อาการที่พบ',
      maxLines: 3,
      hintText: 'เช่น ซึม ไม่กินอาหาร มีไข้ น้ำมูกไหล',
      isRequired: true,
    );
  }
}

// --- Treatment Form ---
class TreatmentForm extends StatelessWidget {
  // Sickness reference (read-only symptoms from SICKNESS record)
  final Map<String, dynamic>? sicknessRef;

  // Selection mode: 'FROM_RECORD' or 'NEW'
  final String? selectionMode;
  final ValueChanged<String> onSelectionModeChanged;

  // Symptoms (editable only when mode = NEW)
  final TextEditingController symptomsController;

  // Disease
  final String? diseaseType;
  final ValueChanged<String?> onDiseaseTypeChanged;
  final TextEditingController otherDiseaseController;

  // Treatment Method
  final String? treatmentMethod;
  final ValueChanged<String?> onTreatmentMethodChanged;
  final TextEditingController otherTreatmentController;

  // Recovery Status
  final String? recoveryStatus;
  final ValueChanged<String?> onRecoveryStatusChanged;

  // Follow-up Date (optional, shown when not recovered)
  final DateTime? followUpDate;
  final ValueChanged<DateTime?> onFollowUpDateChanged;

  const TreatmentForm({
    super.key,
    this.sicknessRef,
    this.selectionMode,
    required this.onSelectionModeChanged,
    required this.symptomsController,
    this.diseaseType,
    required this.onDiseaseTypeChanged,
    required this.otherDiseaseController,
    this.treatmentMethod,
    required this.onTreatmentMethodChanged,
    required this.otherTreatmentController,
    this.recoveryStatus,
    required this.onRecoveryStatusChanged,
    this.followUpDate,
    required this.onFollowUpDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Selection Mode ──
        if (sicknessRef != null) ...[
          Text(
            'เลือกข้อมูลอ้างอิง',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8.h),

          // Option 1: From sickness record
          _SelectionCard(
            selected: selectionMode == 'FROM_RECORD',
            icon: Icons.sick,
            iconColor: Colors.orange.shade700,
            title: 'จากบันทึกการป่วยล่าสุด',
            subtitle: 'อาการ: ${sicknessRef!['illness_symptoms'] ?? '-'}',
            onTap: () => onSelectionModeChanged('FROM_RECORD'),
          ),
          SizedBox(height: 8.h),

          // Option 2: New
          _SelectionCard(
            selected: selectionMode == 'NEW',
            icon: Icons.add_circle_outline,
            iconColor: Colors.blue.shade600,
            title: 'เพิ่มการรักษาใหม่',
            subtitle: 'กรอกอาการเอง',
            onTap: () => onSelectionModeChanged('NEW'),
          ),
          SizedBox(height: 16.h),
        ],

        // ── 2. Symptoms ──
        if (selectionMode == 'NEW' || sicknessRef == null) ...[
          FormTextField(
            controller: symptomsController,
            labelText: 'อาการ',
            maxLines: 3,
            hintText: 'อธิบายอาการป่วยของวัว',
          ),
          SizedBox(height: 16.h),
        ],

        // ── 2. Disease Name Dropdown ──
        FormDropdownField<String>(
          label: 'ชื่อโรค / สาเหตุ',
          value: diseaseType,
          items: const [
            DropdownMenuItem(value: 'LUMPY_SKIN', child: Text('ลัมปีสกิน')),
            DropdownMenuItem(value: 'PARASITE', child: Text('พยาธิ')),
            DropdownMenuItem(value: 'BLOAT', child: Text('ท้องอืด')),
            DropdownMenuItem(value: 'PNEUMONIA', child: Text('ปอดบวม')),
            DropdownMenuItem(value: 'MASTITIS', child: Text('เต้านมอักเสบ')),
            DropdownMenuItem(value: 'FOOT_ROT', child: Text('โรคกีบเน่า')),
            DropdownMenuItem(value: 'DIARRHEA', child: Text('ท้องเสีย')),
            DropdownMenuItem(value: 'OTHER', child: Text('อื่นๆ (ระบุ)')),
          ],
          onChanged: onDiseaseTypeChanged,
        ),
        SizedBox(height: 16.h),

        // Disease OTHER text field
        if (diseaseType == 'OTHER') ...[
          FormTextField(
            controller: otherDiseaseController,
            labelText: 'ระบุชื่อโรค',
            hintText: 'กรอกชื่อโรค',
            isRequired: true,
          ),
          SizedBox(height: 16.h),
        ],

        // ── 3. Treatment Method Dropdown ──
        FormDropdownField<String>(
          label: 'วิธีการรักษา',
          value: treatmentMethod,
          items: const [
            DropdownMenuItem(value: 'ORAL_MED', child: Text('กินยา')),
            DropdownMenuItem(value: 'TOPICAL', child: Text('ทายา')),
            DropdownMenuItem(value: 'INJECTION', child: Text('ฉีดยา')),
            DropdownMenuItem(value: 'VACCINE', child: Text('ฉีดวัคซีน')),
            DropdownMenuItem(value: 'SURGERY', child: Text('ผ่าตัด')),
            DropdownMenuItem(value: 'OTHER', child: Text('อื่นๆ (ระบุ)')),
          ],
          onChanged: onTreatmentMethodChanged,
        ),
        SizedBox(height: 16.h),

        // Treatment OTHER text field
        if (treatmentMethod == 'OTHER') ...[
          FormTextField(
            controller: otherTreatmentController,
            labelText: 'ระบุวิธีการรักษา',
            hintText: 'กรอกรายละเอียดวิธีรักษา',
            isRequired: true,
          ),
          SizedBox(height: 16.h),
        ],

        // ── 4. Recovery Status Dropdown ──
        FormDropdownField<String>(
          label: 'สถานะหลังรักษา',
          value: recoveryStatus,
          items: const [
            DropdownMenuItem(value: 'RECOVERED', child: Text('หายดีแล้ว')),
            DropdownMenuItem(value: 'MONITORING', child: Text('เฝ้าดูอาการ')),
            DropdownMenuItem(value: 'REFERRED', child: Text('ส่งต่อรักษา')),
          ],
          onChanged: onRecoveryStatusChanged,
        ),
        SizedBox(height: 16.h),

        // ── 5. Follow-up Date (optional, shown when not recovered) ──
        if (recoveryStatus != null && recoveryStatus != 'RECOVERED') ...[
          _FollowUpDatePicker(
            followUpDate: followUpDate,
            onDateChanged: onFollowUpDateChanged,
          ),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }
}

// --- Selection Card for Treatment mode ---
class _SelectionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? iconColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? iconColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: selected ? iconColor : Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: iconColor, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

// --- Follow-up Date Picker sub-widget ---
class _FollowUpDatePicker extends StatelessWidget {
  final DateTime? followUpDate;
  final ValueChanged<DateTime?> onDateChanged;

  const _FollowUpDatePicker({
    required this.followUpDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = followUpDate != null
        ? '${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}'
        : 'ยังไม่ได้เลือก';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'วันนัดตรวจ (ถ้ามี)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  followUpDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: 'เลือกวันนัดตรวจ',
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: followUpDate != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                  ),
                ),
                Icon(Icons.calendar_today,
                    size: 18.sp, color: Colors.grey.shade600),
              ],
            ),
          ),
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

// --- Death Form ---
class DeathForm extends StatelessWidget {
  final String? cause;
  final ValueChanged<String?> onCauseChanged;
  final TextEditingController otherDetailsController;

  const DeathForm({
    super.key,
    required this.cause,
    required this.onCauseChanged,
    required this.otherDetailsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormDropdownField<String>(
          label: 'สาเหตุการตาย',
          isRequired: true,
          value: cause,
          items: const [
            DropdownMenuItem(value: 'EPIDEMIC', child: Text('โรคระบาด')),
            DropdownMenuItem(value: 'ACCIDENT', child: Text('อุบัติเหตุ')),
            DropdownMenuItem(value: 'DIGESTIVE', child: Text('ระบบย่อยอาหาร')),
            DropdownMenuItem(value: 'ENVIRONMENT', child: Text('สภาพแวดล้อม')),
            DropdownMenuItem(value: 'UNKNOWN', child: Text('ไม่ทราบสาเหตุ')),
            DropdownMenuItem(value: 'OTHER', child: Text('อื่นๆ (ระบุ)')),
          ],
          onChanged: onCauseChanged,
        ),
        SizedBox(height: 16.h),
        if (cause == 'OTHER')
          FormTextField(
            controller: otherDetailsController,
            labelText: 'ระบุสาเหตุอื่นๆ หรือรายละเอียด',
            maxLines: 3,
            hintText: 'เช่น ขาหัก, กินพลาสติก',
            isRequired: true,
          ),
      ],
    );
  }
}

// --- Generic Form (for Sold, etc.) ---
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
