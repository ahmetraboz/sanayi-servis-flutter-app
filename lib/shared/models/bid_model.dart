class BidModel {
  final int id;
  final int requestId;
  final int? providerId;
  final double price;
  final String description;
  final String estimatedDuration;
  final String status;
  final String? requestTitle;
  final String? requestStatus;
  final String? providerName;
  final String? companyName;
  final String? vehicleBrand;
  final String? vehicleModel;
  final double? averageRating;
  final int? reviewCount;
  final String? proposedDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BidModel({
    required this.id,
    required this.requestId,
    this.providerId,
    required this.price,
    required this.description,
    required this.estimatedDuration,
    required this.status,
    this.requestTitle,
    this.requestStatus,
    this.providerName,
    this.companyName,
    this.vehicleBrand,
    this.vehicleModel,
    this.averageRating,
    this.reviewCount,
    this.proposedDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
    id: json['id'] as int,
    requestId: json['requestId'] as int,
    providerId: json['providerId'] as int?,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    description: json['description'] as String? ?? '',
    estimatedDuration: json['estimatedDuration'] as String? ?? '',
    status: json['status'] as String,
    requestTitle: json['requestTitle'] as String?,
    requestStatus: json['requestStatus'] as String?,
    providerName: json['providerName'] as String?,
    companyName: json['companyName'] as String?,
    vehicleBrand: json['vehicleBrand'] as String?,
    vehicleModel: json['vehicleModel'] as String?,
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    reviewCount: json['reviewCount'] as int?,
    proposedDate: json['proposedDate'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'providerId': providerId,
    'price': price,
    'description': description,
    'estimatedDuration': estimatedDuration,
    'status': status,
    'requestTitle': requestTitle,
    'requestStatus': requestStatus,
    'providerName': providerName,
    'companyName': companyName,
    'vehicleBrand': vehicleBrand,
    'vehicleModel': vehicleModel,
    'averageRating': averageRating,
    'reviewCount': reviewCount,
    'proposedDate': proposedDate,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
