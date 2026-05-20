import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

final reviewApiProvider = Provider<ReviewApiService>((ref) {
  return ReviewApiService(ref.watch(apiClientProvider));
});

class ReviewApiService {
  final ApiClient _client;

  ReviewApiService(this._client);

  Future<Map<String, dynamic>> getServiceReviews(int serviceId, {int page = 1, int limit = 10}) async {
    final response = await _client.get(
      '/api/reviews/service/$serviceId',
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<dynamic> createReview(Map<String, dynamic> data) async {
    final response = await _client.post('/api/reviews', data: data);
    return response.data;
  }
}
