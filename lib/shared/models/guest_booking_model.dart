class GuestBookingModel {
  final int id;
  final String token;
  final String? accessToken;
  final String referenceCode;
  final String? serviceIds;
  final String name;
  final String phone;
  final String city;
  final String status;
  final String brand;
  final String model;
  final String title;
  final String description;
  final int? year;
  final String? licensePlate;
  final String? chassisCode;
  final String? fuelType;
  final String? transmissionType;
  final String? engineDisplacement;
  final String? color;
  final int? mileage;
  final String? imageUrl;
  final String? preferredDate;
  final dynamic damageReports;
  final int? rating;
  final String? reviewComment;
  final DateTime createdAt;

  const GuestBookingModel({
    required this.id,
    required this.token,
    this.accessToken,
    required this.referenceCode,
    this.serviceIds,
    required this.name,
    required this.phone,
    required this.city,
    required this.status,
    required this.brand,
    required this.model,
    required this.title,
    required this.description,
    this.year,
    this.licensePlate,
    this.chassisCode,
    this.fuelType,
    this.transmissionType,
    this.engineDisplacement,
    this.color,
    this.mileage,
    this.imageUrl,
    this.preferredDate,
    this.damageReports,
    this.rating,
    this.reviewComment,
    required this.createdAt,
  });

  factory GuestBookingModel.fromJson(Map<String, dynamic> json) => GuestBookingModel(
    id: json['id'] as int,
    token: json['token'] as String? ?? json['accessToken'] as String? ?? '',
    accessToken: json['accessToken'] as String?,
    referenceCode: json['referenceCode'] as String? ?? '',
    serviceIds: json['serviceIds'] as String?,
    name: json['name'] as String? ?? json['customerName'] as String? ?? '',
    phone: json['phone'] as String? ?? json['customerPhone'] as String? ?? '',
    city: json['city'] as String? ?? '',
    status: json['status'] as String,
    brand: json['brand'] as String? ?? '',
    model: json['model'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    year: json['year'] as int?,
    licensePlate: json['licensePlate'] as String?,
    chassisCode: json['chassisCode'] as String?,
    fuelType: json['fuelType'] as String?,
    transmissionType: json['transmissionType'] as String?,
    engineDisplacement: json['engineDisplacement'] as String?,
    color: json['color'] as String?,
    mileage: json['mileage'] as int?,
    imageUrl: json['imageUrl'] as String?,
    preferredDate: json['preferredDate'] as String?,
    damageReports: json['damageReports'],
    rating: json['rating'] as int?,
    reviewComment: json['reviewComment'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': token,
    'accessToken': accessToken,
    'referenceCode': referenceCode,
    'serviceIds': serviceIds,
    'name': name,
    'phone': phone,
    'city': city,
    'status': status,
    'brand': brand,
    'model': model,
    'title': title,
    'description': description,
    'year': year,
    'licensePlate': licensePlate,
    'chassisCode': chassisCode,
    'fuelType': fuelType,
    'transmissionType': transmissionType,
    'engineDisplacement': engineDisplacement,
    'color': color,
    'mileage': mileage,
    'imageUrl': imageUrl,
    'preferredDate': preferredDate,
    'damageReports': damageReports,
    'rating': rating,
    'reviewComment': reviewComment,
    'createdAt': createdAt.toIso8601String(),
  };
}
