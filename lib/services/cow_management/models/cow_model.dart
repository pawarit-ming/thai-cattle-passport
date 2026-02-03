class Cow {
  final int? animalId;
  final String userId;
  final int farmId;
  final String? nidNumber;
  final String animalName;
  final String? breed;
  final String sex;
  final DateTime? birthDate;
  final int? sireId;
  final String? sireName;
  final int? damId;
  final String? damName;
  final String? color;
  final double? weight;
  final double? height;
  final List<String>? facePic;
  final List<String>? bodyPic;
  final List<String>? markPic;
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
    this.nidNumber,
    required this.animalName,
    this.breed,
    required this.sex,
    this.birthDate,
    this.sireId,
    this.sireName,
    this.damId,
    this.damName,
    this.color,
    this.weight,
    this.height,
    this.facePic,
    this.bodyPic,
    this.markPic,
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
    String? sireName,
    int? damId,
    String? damName,
    String? color,
    double? weight,
    double? height,
    List<String>? facePic,
    List<String>? bodyPic,
    List<String>? markPic,
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
      sireName: sireName ?? this.sireName,
      damId: damId ?? this.damId,
      damName: damName ?? this.damName,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      facePic: facePic ?? this.facePic,
      bodyPic: bodyPic ?? this.bodyPic,
      markPic: markPic ?? this.markPic,
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
      nidNumber: map['nid_number'],
      animalName: map['animal_name'],
      breed: map['breed'],
      sex: map['sex'],
      birthDate:
          map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      sireId: map['sire_id'],
      sireName: map['sire_name'],
      damId: map['dam_id'],
      damName: map['dam_name'],
      color: map['color'],
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      facePic: map['face_pic'] != null
          ? List<String>.from(map['face_pic'] as List)
          : null,
      bodyPic: map['body_pic'] != null
          ? List<String>.from(map['body_pic'] as List)
          : null,
      markPic: map['mark_pic'] != null
          ? List<String>.from(map['mark_pic'] as List)
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
      'birth_date': birthDate?.toIso8601String().substring(0, 10),
      'sire_id': sireId,
      'sire_name': sireName,
      'dam_id': damId,
      'dam_name': damName,
      'color': color,
      'weight': weight,
      'height': height,
      'face_pic': facePic,
      'body_pic': bodyPic,
      'mark_pic': markPic,
      'origin': origin,
      'import_date': importDate?.toIso8601String().substring(0, 10),
      'status': status,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
