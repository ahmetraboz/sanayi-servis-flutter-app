class ServiceModel {
  final int id;
  final String name;
  final String description;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  // Admin / service-profile fields
  final String? companyName;
  final String? status;
  final String? city;
  final String? district;
  final String? address;
  final bool? isVerified;
  final String? taxNumber;
  final String? phone;
  final String? website;
  final String? latitude;
  final String? longitude;
  final String? googlePlaceId;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.isActive,
    required this.createdAt,
    // admin fields
    this.companyName,
    this.status,
    this.city,
    this.district,
    this.address,
    this.isVerified,
    this.taxNumber,
    this.phone,
    this.website,
    this.latitude,
    this.longitude,
    this.googlePlaceId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'] as int,
    name: json['name'] as String? ?? json['companyName'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    // admin fields
    companyName: json['companyName'] as String?,
    status: json['status'] as String?,
    city: json['city'] as String?,
    district: json['district'] as String?,
    address: json['address'] as String?,
    isVerified: json['isVerified'] as bool?,
    taxNumber: json['taxNumber'] as String?,
    phone: json['phone'] as String?,
    website: json['website'] as String?,
    latitude: json['latitude'] as String?,
    longitude: json['longitude'] as String?,
    googlePlaceId: json['googlePlaceId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };
}
