enum ActivityType {
  VACCINE,
  TREATMENT,
  BIRTH,
  WEIGHT_UPDATE,
  BREEDING,
  PREGNANCY_CHECK,
  DEATH,
  SOLD,
  EDIT_LOG;

  String toJson() => name;
  static ActivityType fromJson(String json) => values.byName(json);
}

class Activity {
  final int? id;
  final int animalId;
  final ActivityType activityType;
  final String? description;
  final Map<String, dynamic> data;
  final DateTime activityDate;
  final DateTime? createdAt;

  Activity({
    this.id,
    required this.animalId,
    required this.activityType,
    this.description,
    this.data = const {},
    required this.activityDate,
    this.createdAt,
  });

  Activity copyWith({
    int? id,
    int? animalId,
    ActivityType? activityType,
    String? description,
    Map<String, dynamic>? data,
    DateTime? activityDate,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      data: data ?? this.data,
      activityDate: activityDate ?? this.activityDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // fromMap
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      animalId: map['animal_id'],
      activityType: ActivityType.fromJson(map['activity_type']),
      description: map['description'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : {},
      activityDate: DateTime.parse(map['activity_date']),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  // toMap for insertion
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
      'description': description,
      'data': data,
      'activity_date': activityDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}