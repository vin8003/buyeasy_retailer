class UserModel {
  final int id;
  final String username;
  final String email;
  final String shopName;
  final String? shopImage;
  final bool isPhoneVerified;
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.shopName,
    this.shopImage,
    this.isPhoneVerified = false,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      shopName: json['shop_name'] ?? '',
      shopImage: json['shop_image'],
      isPhoneVerified: json['is_phone_verified'] ?? false,
      phoneNumber: json['phone_number'] ?? '',
    );
  }
}
