class District {
  final int id;
  final String nameTh;
  final String nameEn;
  final int provinceId;

  District({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.provinceId,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      nameTh: json['name_th'],
      nameEn: json['name_en'],
      provinceId: json['province_id'],
    );
  }
}
