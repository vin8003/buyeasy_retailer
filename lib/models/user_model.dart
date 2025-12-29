class UserModel {
  final int id;
  final String username;
  final String email;
  final String shopName;
  final String? shopImage;
  final bool isPhoneVerified;
  final String phoneNumber;
  final String shopDescription;
  final String contactEmail;
  final String contactPhone;
  final String whatsappNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final double? latitude;
  final double? longitude;
  final String businessType;
  final String gstNumber;
  final String panNumber;
  final bool offersDelivery;
  final bool offersPickup;
  final double minimumOrderAmount;
  final int deliveryRadius;
  final List<String> serviceablePincodes;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.shopName,
    this.shopImage,
    this.isPhoneVerified = false,
    required this.phoneNumber,
    this.shopDescription = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.whatsappNumber = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.businessType = '',
    this.gstNumber = '',
    this.panNumber = '',
    this.offersDelivery = true,
    this.offersPickup = true,
    this.minimumOrderAmount = 0,
    this.deliveryRadius = 5,
    this.serviceablePincodes = const [],
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
      shopDescription: json['shop_description'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      businessType: json['business_type'] ?? '',
      gstNumber: json['gst_number'] ?? '',
      panNumber: json['pan_number'] ?? '',
      offersDelivery: json['offers_delivery'] ?? true,
      offersPickup: json['offers_pickup'] ?? true,
      minimumOrderAmount: double.parse(
        (json['minimum_order_amount'] ?? 0).toString(),
      ),
      deliveryRadius: json['delivery_radius'] ?? 5,
      serviceablePincodes: List<String>.from(
        json['serviceable_pincodes'] ?? [],
      ),
    );
  }
}
