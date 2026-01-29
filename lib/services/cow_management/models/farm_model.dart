class Farm {
  final int id;
  final String userId;
  final String farmName;
  final String? address;
  final String? subDistrict;
  final String? district;
  final String province;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool status;
  final DateTime? createdAt;

  Farm({
    required this.id,
    required this.userId,
    required this.farmName,
    this.address,
    this.subDistrict,
    this.district,
    required this.province,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.status = true,
    this.createdAt,
  });

  Farm copyWith({
    int? id,
    String? userId,
    String? farmName,
    String? address,
    String? subDistrict,
    String? district,
    String? province,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? status,
    DateTime? createdAt,
  }) {
    return Farm(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      farmName: farmName ?? this.farmName,
      address: address ?? this.address,
      subDistrict: subDistrict ?? this.subDistrict,
      district: district ?? this.district,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // fromMap
  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'],
      userId: map['user_id'],
      farmName: map['farm_name'],
      address: map['address'],
      subDistrict: map['sub_district'],
      district: map['district'],
      province: map['province'],
      postalCode: map['postal_code'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      status: map['status'] ?? true,
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
      'user_id': userId,
      'farm_name': farmName,
      'address': address,
      'sub_district': subDistrict,
      'district': district,
      'province': province,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
