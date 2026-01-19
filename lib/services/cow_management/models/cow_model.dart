class Cow {
  final int? animalId;
  final int farmId;
  final int userId;
  final String nidNumber;
  final String animalIdMarkType;
  final String? markNumber;
  final String breed;
  final String isFirstBreed;
  final String animalStatus;
  final String animalName;
  final DateTime birthDate;
  final String sex;
  final int? sireId;
  final int? damId;
  final String origin;
  final String? originCountry;
  final DateTime? importDate;
  final String animalColor;
  final double height;
  final double weight;
  final String eyeColor;
  final String noseColor;
  final String? fullBodyPic;
  final String? facePic;
  final String? markPic;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cow({
    this.animalId,
    required this.farmId,
    required this.userId,
    required this.nidNumber,
    this.animalIdMarkType = '0',
    this.markNumber,
    required this.breed,
    this.isFirstBreed = '0',
    this.animalStatus = '4',
    required this.animalName,
    required this.birthDate,
    required this.sex,
    this.sireId,
    this.damId,
    this.origin = '0',
    this.originCountry,
    this.importDate,
    required this.animalColor,
    required this.height,
    required this.weight,
    required this.eyeColor,
    required this.noseColor,
    this.fullBodyPic,
    this.facePic,
    this.markPic,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Cow copyWith({
    int? animalId,
    String? nidNumber,
    String? animalName,
    String? breed,
    double? weight,
    double? height,
    String? animalColor,
    String? animalStatus,
    String? sex,
    DateTime? birthDate,
    int? sireId,
    int? damId,
    String? facePic,
    String? fullBodyPic,
    String? markPic,
    DateTime? updatedAt,
  }) {
    return Cow(
      animalId: animalId ?? this.animalId,
      farmId: this.farmId,
      userId: this.userId,
      nidNumber: nidNumber ?? this.nidNumber,
      animalName: animalName ?? this.animalName,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      animalColor: animalColor ?? this.animalColor,
      animalStatus: animalStatus ?? this.animalStatus,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      sireId: sireId ?? this.sireId,
      damId: damId ?? this.damId,
      facePic: facePic ?? this.facePic,
      fullBodyPic: fullBodyPic ?? this.fullBodyPic,
      markPic: markPic ?? this.markPic,
      updatedAt: updatedAt ?? this.updatedAt,
      eyeColor: '',
      noseColor: '',
    );
  }

  // fromMap
  factory Cow.fromMap(Map<String, dynamic> map) {
    return Cow(
      animalId: map['animal_id'],
      farmId: map['farm_id'],
      userId: map['user_id'],
      nidNumber: map['nid_number'],
      animalIdMarkType: map['animal_id_mark_type'],
      markNumber: map['mark_number'],
      breed: map['breed'],
      isFirstBreed: map['is_first_breed'],
      animalStatus: map['animal_status'],
      animalName: map['animal_name'],
      birthDate: DateTime.parse(map['birth_date']),
      sex: map['sex'],
      sireId: map['sire_id'],
      damId: map['dam_id'],
      origin: map['origin'],
      originCountry: map['origin_country'],
      importDate: map['import_date'] != null
          ? DateTime.parse(map['import_date'])
          : null,
      animalColor: map['animal_color'],
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      eyeColor: map['eye_color'],
      noseColor: map['nose_color'],
      fullBodyPic: map['full_body_pic'],
      facePic: map['face_pic'],
      markPic: map['mark_pic'],
      isDeleted: map['is_deleted'],
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
      'farm_id': farmId,
      'user_id': userId,
      'nid_number': nidNumber,
      'animal_id_mark_type': animalIdMarkType,
      'mark_number': markNumber,
      'breed': breed,
      'is_first_breed': isFirstBreed,
      'animal_status': animalStatus,
      'animal_name': animalName,
      'birth_date':
          birthDate.toIso8601String().substring(0, 10), // Format as YYYY-MM-DD
      'sex': sex,
      'sire_id': sireId,
      'dam_id': damId,
      'origin': origin,
      'origin_country': originCountry,
      'import_date': importDate
          ?.toIso8601String()
          .substring(0, 10), // Format as YYYY-MM-DD
      'animal_color': animalColor,
      'height': height,
      'weight': weight,
      'eye_color': eyeColor,
      'nose_color': noseColor,
      'full_body_pic': fullBodyPic,
      'face_pic': facePic,
      'mark_pic': markPic,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
