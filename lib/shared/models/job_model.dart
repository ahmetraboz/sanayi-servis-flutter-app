class JobModel {
  final int id;
  final int requestId;
  final int providerId;
  final int customerId;
  final String status;
  final double agreedPrice;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobModel({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.customerId,
    required this.status,
    required this.agreedPrice,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
    id: json['id'] as int,
    requestId: json['requestId'] as int,
    providerId: json['providerId'] as int,
    customerId: json['customerId'] as int,
    status: json['status'] as String,
    agreedPrice: double.tryParse(json['agreedPrice']?.toString() ?? '') ?? 0.0,
    startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'] as String) : null,
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'providerId': providerId,
    'customerId': customerId,
    'status': status,
    'agreedPrice': agreedPrice,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
