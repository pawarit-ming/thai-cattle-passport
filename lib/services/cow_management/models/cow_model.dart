class Cow {
  final int? animalId;
  final String userId;
  final int farmId;
  final String nidNumber;
  final String animalName;
  final String? breed;
  final String sex;
  final DateTime? birthDate;
  final int? sireId;
  final int? damId;
  final String? color;
  final double? weight;
  final double? height;
  final List<String>? facePic;
  final List<String>? bodyPic;
  final String? origin;
  final DateTime? importDate;
  final String status;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cow({
    this.animalId,
    required this.userId,
    required this.farmId,
    required this.nidNumber,
    required this.animalName,
    this.breed,
    required this.sex,
    this.birthDate,
    this.sireId,
    this.damId,
    this.color,
    this.weight,
    this.height,
    this.facePic,
    this.bodyPic,
    this.origin,
    this.importDate,
    this.status = 'ACTIVE',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Cow copyWith({
    int? animalId,
    String? userId,
    int? farmId,
    String? nidNumber,
    String? animalName,
    String? breed,
    String? sex,
    DateTime? birthDate,
    int? sireId,
    int? damId,
    String? color,
    double? weight,
    double? height,
    List<String>? facePic,
    List<String>? bodyPic,
    String? origin,
    DateTime? importDate,
    String? status,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Cow(
      animalId: animalId ?? this.animalId,
      userId: userId ?? this.userId,
      farmId: farmId ?? this.farmId,
      nidNumber: nidNumber ?? this.nidNumber,
      animalName: animalName ?? this.animalName,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      sireId: sireId ?? this.sireId,
      damId: damId ?? this.damId,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      facePic: facePic ?? this.facePic,
      bodyPic: bodyPic ?? this.bodyPic,
      origin: origin ?? this.origin,
      importDate: importDate ?? this.importDate,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // fromMap
  factory Cow.fromMap(Map<String, dynamic> map) {
    return Cow(
      animalId: map['animal_id'],
      userId: map['user_id'],
      farmId: map['farm_id'],
      nidNumber: map['nid_number'] ?? '',
      animalName: map['animal_name'],
      breed: map['breed'],
      sex: map['sex'],
      birthDate:
          map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      sireId: map['sire_id'],
      damId: map['dam_id'],
      color: map['color'],
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      facePic: map['face_pic'] != null
          ? List<String>.from(map['face_pic'] as List)
          : null,
      bodyPic: map['body_pic'] != null
          ? List<String>.from(map['body_pic'] as List)
          : null,
      origin: map['origin'],
      importDate: map['import_date'] != null
          ? DateTime.parse(map['import_date'])
          : null,
      status: map['status'] ?? 'ACTIVE',
      isDeleted: map['is_deleted'] ?? false,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // toMap for insertion (omits auto-generated fields)
  Map<String, dynamic> toMapForInsert() {
    final map = toMap();
    map.remove('animal_id');
    map.remove('created_at');
    map.remove('updated_at');
    return map;
  }

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'animal_id': animalId,
      'user_id': userId,
      'farm_id': farmId,
      'nid_number': nidNumber,
      'animal_name': animalName,
      'breed': breed,
      'sex': sex,
      'birth_date': birthDate != null
          ? birthDate!.toIso8601String().substring(0, 10)
          : null,
      'sire_id': sireId,
      'dam_id': damId,
      'color': color,
      'weight': weight,
      'height': height,
      'face_pic': facePic,
      'body_pic': bodyPic,
      'origin': origin,
      'import_date': importDate != null
          ? importDate!.toIso8601String().substring(0, 10)
          : null,
      'status': status,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
