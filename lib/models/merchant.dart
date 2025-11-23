class Merchant {
  final String id;
  final String name;
  final String nameEn;
  final String phone;
  final String email;
  final String code;
  final List<String> terminals;

  Merchant({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.phone,
    required this.email,
    required this.code,
    required this.terminals,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      code: json['code'] as String,
      terminals: List<String>.from(json['terminals'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'phone': phone,
      'email': email,
      'code': code,
      'terminals': terminals,
    };
  }
}

