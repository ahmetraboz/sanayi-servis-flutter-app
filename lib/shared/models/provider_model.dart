class ProviderModel {
  final int id;
  final String companyName;
  final String city;
  final String? district;
  final String? logoUrl;
  final bool isVerified;
  final String? averageRating;
  final int totalReviews;
  final int totalJobs;
  final String? description;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? googlePlaceId;

  const ProviderModel({
    required this.id,
    required this.companyName,
    required this.city,
    this.district,
    this.logoUrl,
    required this.isVerified,
    this.averageRating,
    required this.totalReviews,
    required this.totalJobs,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.googlePlaceId,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) => ProviderModel(
        id: json['id'] as int,
        companyName: json['companyName'] as String,
        city: json['city'] as String,
        district: json['district'] as String?,
        logoUrl: json['logoUrl'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        averageRating: json['averageRating'] as String?,
        totalReviews: json['totalReviews'] as int? ?? 0,
        totalJobs: json['totalJobs'] as int? ?? 0,
        description: json['description'] as String?,
        address: json['address'] as String?,
        latitude: json['latitude'] as String?,
        longitude: json['longitude'] as String?,
        googlePlaceId: json['googlePlaceId'] as String?,
      );

  String get mapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(companyName)}';
  }
}

class ReviewModel {
  final int id;
  final int rating;
  final String? comment;
  final String reviewerName;
  final String createdAt;

  const ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.reviewerName,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as int,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        reviewerName: json['reviewerName'] as String? ?? 'Anonim',
        createdAt: json['createdAt'] as String,
      );
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        page: json['page'] as int,
        limit: json['limit'] as int,
        total: json['total'] as int,
        totalPages: json['totalPages'] as int,
      );

  bool get hasNext => page < totalPages;
}
