class Vaccine {
  final String id;
  final String nameTh;
  final String nameEn;
  final int totalDoses;
  final int? doseGapDays;
  final int? boosterIntervalDays;
  final String? genderFilter; // NULL = ทุกเพศ, 'FEMALE', 'MALE'
  final String? note;
  final bool isActive;

  const Vaccine({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.totalDoses,
    this.doseGapDays,
    this.boosterIntervalDays,
    this.genderFilter,
    this.note,
    this.isActive = true,
  });

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'] as String,
      nameTh: map['name_th'] as String,
      nameEn: map['name_en'] as String,
      totalDoses: map['total_doses'] as int,
      doseGapDays: map['dose_gap_days'] as int?,
      boosterIntervalDays: map['booster_interval_days'] as int?,
      genderFilter: map['gender_filter'] as String?,
      note: map['note'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  /// คำนวณวันนัดเข็มถัดไป
  /// [doseNumber] = เข็มที่เพิ่งฉีด (1, 2, ...)
  /// [vaccinatedDate] = วันที่ฉีด
  DateTime? getNextDoseDate(int doseNumber, DateTime vaccinatedDate) {
    if (doseNumber < totalDoses && doseGapDays != null) {
      // ยังไม่ครบเข็ม → นัดเข็มถัดไป
      return vaccinatedDate.add(Duration(days: doseGapDays!));
    } else if (doseNumber >= totalDoses && boosterIntervalDays != null) {
      // ครบเข็มแล้ว → นัดฉีดซ้ำ (booster)
      return vaccinatedDate.add(Duration(days: boosterIntervalDays!));
    }
    // ไม่ต้องฉีดซ้ำ (เช่น Brucellosis)
    return null;
  }

  /// ข้อความเข็มที่
  String getDoseLabel(int doseNumber) {
    if (doseNumber <= totalDoses) {
      return 'เข็มที่ $doseNumber';
    }
    return 'ฉีดซ้ำ';
  }

  /// รายการตัวเลือกเข็ม
  List<int> get doseOptions {
    final options = List.generate(totalDoses, (i) => i + 1);
    if (boosterIntervalDays != null) {
      options.add(totalDoses + 1); // +1 = booster
    }
    return options;
  }

  String get displayName => '$nameTh ($nameEn)';
}
