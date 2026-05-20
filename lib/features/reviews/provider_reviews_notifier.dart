import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ReviewItem {
  final int id;
  final int rating;
  final String? comment;
  final String? providerReply;
  final String? repliedAt;
  final String createdAt;
  final String customerName;
  final String requestTitle;
  final int requestId;

  const ReviewItem({
    required this.id,
    required this.rating,
    this.comment,
    this.providerReply,
    this.repliedAt,
    required this.createdAt,
    required this.customerName,
    required this.requestTitle,
    required this.requestId,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> j) => ReviewItem(
        id: j['id'] as int,
        rating: j['rating'] as int? ?? 0,
        comment: j['comment'] as String?,
        providerReply: j['providerReply'] as String?,
        repliedAt: j['repliedAt'] as String?,
        createdAt: j['createdAt'] as String? ?? '',
        customerName: j['customerName'] as String? ?? '',
        requestTitle: j['requestTitle'] as String? ?? '',
        requestId: j['requestId'] as int? ?? 0,
      );

  ReviewItem copyWith({Object? providerReply = _sentinel, Object? repliedAt = _sentinel}) => ReviewItem(
        id: id,
        rating: rating,
        comment: comment,
        providerReply: identical(providerReply, _sentinel) ? this.providerReply : providerReply as String?,
        repliedAt: identical(repliedAt, _sentinel) ? this.repliedAt : repliedAt as String?,
        createdAt: createdAt,
        customerName: customerName,
        requestTitle: requestTitle,
        requestId: requestId,
      );
}

class ProviderReviewsState {
  final bool loading;
  final String? error;
  final List<ReviewItem> reviews;
  final double? averageRating;
  final int totalReviews;
  final int? replyingId;
  final String? replyError;
  final int currentPage;
  final int totalPages;

  const ProviderReviewsState({
    this.loading = true,
    this.error,
    this.reviews = const [],
    this.averageRating,
    this.totalReviews = 0,
    this.replyingId,
    this.replyError,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  Map<int, int> get starBuckets {
    final buckets = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final s = r.rating.clamp(1, 5);
      buckets[s] = (buckets[s] ?? 0) + 1;
    }
    return buckets;
  }

  ProviderReviewsState copyWith({
    bool? loading,
    Object? error = _sentinel,
    List<ReviewItem>? reviews,
    Object? averageRating = _sentinel,
    int? totalReviews,
    Object? replyingId = _sentinel,
    Object? replyError = _sentinel,
    int? currentPage,
    int? totalPages,
  }) {
    return ProviderReviewsState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      reviews: reviews ?? this.reviews,
      averageRating: identical(averageRating, _sentinel) ? this.averageRating : averageRating as double?,
      totalReviews: totalReviews ?? this.totalReviews,
      replyingId: identical(replyingId, _sentinel) ? this.replyingId : replyingId as int?,
      replyError: identical(replyError, _sentinel) ? this.replyError : replyError as String?,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class ProviderReviewsNotifier extends StateNotifier<ProviderReviewsState> {
  final ApiClient _api;

  ProviderReviewsNotifier(this._api) : super(const ProviderReviewsState()) {
    fetchReviews();
  }

  Future<void> fetchReviews({int page = 1}) async {
    if (!mounted) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/provider/reviews', queryParameters: {'page': '$page', 'limit': '10'});
      final data = res.data as Map<String, dynamic>;
      final list = (data['data'] as List? ?? [])
          .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final avg = data['averageRating'];
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        reviews: list,
        averageRating: avg != null ? (avg as num).toDouble() : null,
        totalReviews: data['totalReviews'] as int? ?? pagination['total'] as int? ?? list.length,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.message ?? 'Değerlendirmeler yüklenemedi');
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      fetchReviews(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      fetchReviews(page: state.currentPage - 1);
    }
  }

  Future<bool> submitReply(int reviewId, String reply) async {
    state = state.copyWith(replyingId: reviewId, replyError: null);
    try {
      await _api.post('/api/provider/reviews/$reviewId/reply', data: {'reply': reply});
      state = state.copyWith(
        replyingId: null,
        reviews: state.reviews.map((r) {
          if (r.id == reviewId) return r.copyWith(providerReply: reply, repliedAt: DateTime.now().toIso8601String());
          return r;
        }).toList(),
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(replyingId: null, replyError: e.message ?? 'Yanıt gönderilemedi');
      return false;
    }
  }
}

final providerReviewsProvider = StateNotifierProvider.autoDispose<ProviderReviewsNotifier, ProviderReviewsState>(
  (ref) => ProviderReviewsNotifier(ref.read(apiClientProvider)),
);
