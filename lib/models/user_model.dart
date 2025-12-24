class UserModel {
  final int id;
  final String username;
  final String email;
  final String shopName;
  final String? shopImage;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.shopName,
    this.shopImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      shopName: json['shop_name'] ?? '',
      shopImage: json['shop_image'],
    );
  }
}
