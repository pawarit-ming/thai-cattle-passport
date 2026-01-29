enum UserRole {
  ADMIN,
  FARMER,
  VET;

  String toJson() => name;
  static UserRole fromJson(String json) => values.byName(json);
}

class User {
  final String id; // UUID from auth.users
  final UserRole role;
  final String? title;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String? mobilePhone;
  final String? address;
  final String? province;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    this.role = UserRole.FARMER,
    this.title,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.mobilePhone,
    this.address,
    this.province,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? id,
    UserRole? role,
    String? title,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? mobilePhone,
    String? address,
    String? province,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      title: title ?? this.title,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      address: address ?? this.address,
      province: province ?? this.province,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // fromMap
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      role: UserRole.fromJson(map['role'] ?? 'FARMER'),
      title: map['title'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date']) : null,
      mobilePhone: map['mobile_phone'],
      address: map['address'],
      province: map['province'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // toMap for insertion
  Map<String, dynamic> toMapForInsert() {
    final map = toMap();
    map.remove('id');
    map.remove('created_at');
    map.remove('updated_at');
    return map;
  }

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role.toJson(),
      'title': title,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate?.toIso8601String().substring(0, 10),
      'mobile_phone': mobilePhone,
      'address': address,
      'province': province,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
