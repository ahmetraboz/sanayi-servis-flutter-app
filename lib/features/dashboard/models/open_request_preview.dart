class OpenRequestPreview {
  final int id;
  final String title;
  final String status;
  final String problemCategory;
  final String urgencyLevel;
  final String vehicleBrand;
  final String vehicleModel;
  final int? vehicleYear;
  final String customerName;
  final String createdAt;

  const OpenRequestPreview({
    required this.id,
    required this.title,
    required this.status,
    required this.problemCategory,
    required this.urgencyLevel,
    required this.vehicleBrand,
    required this.vehicleModel,
    this.vehicleYear,
    required this.customerName,
    required this.createdAt,
  });

  factory OpenRequestPreview.fromJson(Map<String, dynamic> json) => OpenRequestPreview(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? '',
        problemCategory: json['problemCategory'] as String? ?? '',
        urgencyLevel: json['urgencyLevel'] as String? ?? 'normal',
        vehicleBrand: json['vehicleBrand'] as String? ?? '',
        vehicleModel: json['vehicleModel'] as String? ?? '',
        vehicleYear: json['vehicleYear'] as int?,
        customerName: json['customerName'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );

  String get vehicleInfo =>
      '$vehicleBrand $vehicleModel${vehicleYear != null ? ' ($vehicleYear)' : ''}';
}
