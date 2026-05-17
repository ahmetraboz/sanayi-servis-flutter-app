class ProviderStats {
  final int openRequests;
  final int pendingBids;
  final int acceptedBids;
  final int completedBids;
  final int totalBids;
  final String averageRating;
  final int totalReviews;

  const ProviderStats({
    required this.openRequests,
    required this.pendingBids,
    required this.acceptedBids,
    required this.completedBids,
    required this.totalBids,
    required this.averageRating,
    required this.totalReviews,
  });

  factory ProviderStats.fromJson(Map<String, dynamic> json) => ProviderStats(
        openRequests: json['openRequests'] as int? ?? 0,
        pendingBids: json['pendingBids'] as int? ?? 0,
        acceptedBids: json['acceptedBids'] as int? ?? 0,
        completedBids: json['completedBids'] as int? ?? 0,
        totalBids: json['totalBids'] as int? ?? 0,
        averageRating: (json['averageRating'] ?? '0.0').toString(),
        totalReviews: json['totalReviews'] as int? ?? 0,
      );
}
