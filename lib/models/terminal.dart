class Terminal {
  final String id;
  final String merchantId;
  final String code;
  final String name;
  final String nameEn;
  final String location;
  final String locationEn;

  Terminal({
    required this.id,
    required this.merchantId,
    required this.code,
    required this.name,
    required this.nameEn,
    required this.location,
    required this.locationEn,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    return Terminal(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      location: json['location'] as String,
      locationEn: json['locationEn'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'code': code,
      'name': name,
      'nameEn': nameEn,
      'location': location,
      'locationEn': locationEn,
    };
  }
}

