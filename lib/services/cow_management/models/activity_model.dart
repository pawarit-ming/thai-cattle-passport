enum ActivityType {
  VACCINE,
  BIRTH,
  TREATMENT,
  EDIT_LOG;

  String toJson() => name;
  static ActivityType fromJson(String json) => values.byName(json);
}

class Activity {
  final int? id;
  final int animalId;
  final ActivityType activityType; // 'VACCINE', 'BIRTH', 'TREATMENT', 'EDIT_LOG'
  final DateTime activityDate;
  final String? description;
  final Map<String, dynamic> data; // สำหรับเก็บ JSONB
  final DateTime? createdAt;

  Activity({
    this.id,
    required this.animalId,
    required this.activityType,
    required this.activityDate,
    this.description,
    this.data = const {}, // ค่า Default เป็น Map ว่าง
    this.createdAt,
  });

  // copyWith มาตรฐานเดียวกับ Cow
  Activity copyWith({
    int? id,
    int? animalId,
    ActivityType? activityType,
    DateTime? activityDate,
    String? description,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      activityType: activityType ?? this.activityType,
      activityDate: activityDate ?? this.activityDate,
      description: description ?? this.description,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // fromMap
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      animalId: map['animal_id'],
      activityType: ActivityType.fromJson(map['activity_type']),
      activityDate: DateTime.parse(map['activity_date']),
      description: map['description'],
      // จัดการ JSONB ให้เป็น Map ที่ปลอดภัย
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : {},
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }

  // toMapForInsert (ตัด id และ created_at ออกเหมือน Cow)
  Map<String, dynamic> toMapForInsert() {
    final map = toMap();
    map.remove('id');
    map.remove('created_at');
    return map;
  }

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'activity_type': activityType.toJson(),
      // activity_date เป็น Timestamp ต้องส่งเวลาไปด้วย ไม่ต้อง substring(0,10)
      'activity_date': activityDate.toIso8601String(), 
      'description': description,
      'data': data, // Supabase จะแปลง Map นี้เป็น JSONB ให้เอง
      'created_at': createdAt?.toIso8601String(),
    };
  }
}