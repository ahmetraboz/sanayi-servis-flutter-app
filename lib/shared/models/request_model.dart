class RequestModel {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String status;
  final String? problemCategory;
  final String? urgencyLevel;
  final String? imageUrl;
  final int? vehicleId;
  final String? vehicleBrand;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final String? vehicleFuelType;
  final String? vehicleTransmissionType;
  final String? vehicleEngineDisplacement;
  final String? vehicleBodyType;
  final String? vehicleColor;
  final String? vehicleDriveType;
  final String? customerName;
  final String? customerPhone;
  final String? userEmail;
  final String? aiDetectedPart;
  final double? aiConfidence;
  final dynamic damageReports;
  final String? preferredDateFrom;
  final String? preferredDateTo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RequestModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    this.problemCategory,
    this.urgencyLevel,
    this.imageUrl,
    this.vehicleId,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlate,
    this.vehicleFuelType,
    this.vehicleTransmissionType,
    this.vehicleEngineDisplacement,
    this.vehicleBodyType,
    this.vehicleColor,
    this.vehicleDriveType,
    this.customerName,
    this.customerPhone,
    this.userEmail,
    this.aiDetectedPart,
    this.aiConfidence,
    this.damageReports,
    this.preferredDateFrom,
    this.preferredDateTo,
    required this.createdAt,
    this.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) => RequestModel(
    id: json['id'] as int,
    userId: json['userId'] as int? ?? 0,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    status: json['status'] as String,
    problemCategory: json['problemCategory'] as String?,
    urgencyLevel: json['urgencyLevel'] as String?,
    imageUrl: json['imageUrl'] as String?,
    vehicleId: json['vehicleId'] as int?,
    vehicleBrand: json['vehicleBrand'] as String?,
    vehicleModel: json['vehicleModel'] as String?,
    vehicleYear: json['vehicleYear'] as int?,
    vehiclePlate: json['vehiclePlate'] as String?,
    vehicleFuelType: json['vehicleFuelType'] as String?,
    vehicleTransmissionType: json['vehicleTransmissionType'] as String?,
    vehicleEngineDisplacement: json['vehicleEngineDisplacement'] as String?,
    vehicleBodyType: json['vehicleBodyType'] as String?,
    vehicleColor: json['vehicleColor'] as String?,
    vehicleDriveType: json['vehicleDriveType'] as String?,
    customerName: json['customerName'] as String? ?? json['userName'] as String?,
    customerPhone: json['customerPhone'] as String?,
    userEmail: json['userEmail'] as String?,
    aiDetectedPart: json['aiDetectedPart'] as String?,
    aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
    damageReports: json['damageReports'],
    preferredDateFrom: json['preferredDateFrom'] as String?,
    preferredDateTo: json['preferredDateTo'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'status': status,
    'problemCategory': problemCategory,
    'urgencyLevel': urgencyLevel,
    'imageUrl': imageUrl,
    'vehicleId': vehicleId,
    'vehicleBrand': vehicleBrand,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehiclePlate': vehiclePlate,
    'vehicleFuelType': vehicleFuelType,
    'vehicleTransmissionType': vehicleTransmissionType,
    'vehicleEngineDisplacement': vehicleEngineDisplacement,
    'vehicleBodyType': vehicleBodyType,
    'vehicleColor': vehicleColor,
    'vehicleDriveType': vehicleDriveType,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'userEmail': userEmail,
    'aiDetectedPart': aiDetectedPart,
    'aiConfidence': aiConfidence,
    'damageReports': damageReports,
    'preferredDateFrom': preferredDateFrom,
    'preferredDateTo': preferredDateTo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
