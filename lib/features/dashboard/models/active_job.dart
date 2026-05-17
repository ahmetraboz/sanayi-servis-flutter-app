class ActiveJob {
  final int id;
  final String title;
  final String status;
  final String urgencyLevel;
  final String vehicleBrand;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final String customerName;
  final String updatedAt;

  const ActiveJob({
    required this.id,
    required this.title,
    required this.status,
    required this.urgencyLevel,
    required this.vehicleBrand,
    required this.vehicleModel,
    this.vehicleYear,
    this.vehiclePlate,
    required this.customerName,
    required this.updatedAt,
  });

  factory ActiveJob.fromJson(Map<String, dynamic> json) => ActiveJob(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? '',
        urgencyLevel: json['urgencyLevel'] as String? ?? 'normal',
        vehicleBrand: json['vehicleBrand'] as String? ?? '',
        vehicleModel: json['vehicleModel'] as String? ?? '',
        vehicleYear: json['vehicleYear'] as int?,
        vehiclePlate: json['vehiclePlate'] as String?,
        customerName: json['customerName'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
      );

  String get vehicleInfo =>
      '$vehicleBrand $vehicleModel${vehicleYear != null ? ' ($vehicleYear)' : ''}';
}
