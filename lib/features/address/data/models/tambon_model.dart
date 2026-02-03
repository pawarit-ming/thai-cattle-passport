class Tambon {
  final int id;
  final String nameTh;
  final String nameEn;
  final int districtId;
  final int zipCode;

  Tambon({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.districtId,
    required this.zipCode,
  });

  factory Tambon.fromJson(Map<String, dynamic> json) {
    return Tambon(
      id: json['id'],
      nameTh: json['name_th'],
      nameEn: json['name_en'],
      districtId: json['district_id'],
      zipCode: json['zip_code'],
    );
  }
}
