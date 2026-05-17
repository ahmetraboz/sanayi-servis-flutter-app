class VehicleModel {
  final int id;
  final int userId;
  final String brand;
  final String model;
  final int? year;
  final String? plate;
  final String? fuelType;
  final String? transmissionType;
  final String? engineDisplacement;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.year,
    this.plate,
    this.fuelType,
    this.transmissionType,
    this.engineDisplacement,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'] as int,
    userId: json['userId'] as int,
    brand: json['brand'] as String,
    model: json['model'] as String,
    year: json['year'] as int?,
    plate: json['plate'] as String?,
    fuelType: json['fuelType'] as String?,
    transmissionType: json['transmissionType'] as String?,
    engineDisplacement: json['engineDisplacement'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'brand': brand,
    'model': model,
    'year': year,
    'plate': plate,
    'fuelType': fuelType,
    'transmissionType': transmissionType,
    'engineDisplacement': engineDisplacement,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
