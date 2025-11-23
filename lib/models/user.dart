enum UserRole {
  admin,
  merchant,
}

class User {
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String? merchantId;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.merchantId,
  });

  factory User.admin({
    required String id,
    required String username,
    required String email,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      role: UserRole.admin,
    );
  }

  factory User.merchant({
    required String id,
    required String username,
    required String email,
    required String merchantId,
  }) {
    return User(
      id: id,
      username: username,
      email: email,
      role: UserRole.merchant,
      merchantId: merchantId,
    );
  }
}

