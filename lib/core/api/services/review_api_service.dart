import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

final reviewApiProvider = Provider<ReviewApiService>((ref) {
  return ReviewApiService(ref.watch(apiClientProvider));
});

class ReviewApiService {
  final ApiClient _client;

  ReviewApiService(this._client);

  Future<List<dynamic>> getServiceReviews(int serviceId) async {
    final response = await _client.get('/api/reviews/service/$serviceId');
    return response.data as List;
  }

  Future<dynamic> createReview(Map<String, dynamic> data) async {
    final response = await _client.post('/api/reviews', data: data);
    return response.data;
  }
}
