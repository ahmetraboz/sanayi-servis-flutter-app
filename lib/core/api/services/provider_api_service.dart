import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../../../shared/models/bid_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/request_model.dart';
import '../../../shared/models/guest_booking_model.dart';

final providerApiProvider = Provider<ProviderApiService>((ref) {
  return ProviderApiService(ref.watch(apiClientProvider));
});

class ProviderApiService {
  final ApiClient _client;

  ProviderApiService(this._client);

  Future<List<BidModel>> getBids() async {
    final response = await _client.get('/api/provider/bids');
    final data = response.data as List;
    return data.map((json) => BidModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<BidModel> createBid(Map<String, dynamic> data) async {
    final response = await _client.post('/api/provider/bids', data: data);
    return BidModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<JobModel>> getJobs() async {
    final response = await _client.get('/api/provider/jobs');
    final data = response.data as List;
    return data.map((json) => JobModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<dynamic>> getReviews() async {
    final response = await _client.get('/api/provider/reviews');
    return response.data as List;
  }

  Future<List<GuestBookingModel>> getGuestBookings() async {
    final response = await _client.get('/api/provider/guest-bookings');
    final data = response.data as List;
    return data.map((json) => GuestBookingModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<GuestBookingModel> getGuestBooking(int id) async {
    final response = await _client.get('/api/provider/guest-bookings/$id');
    return GuestBookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RequestModel>> getRequests() async {
    final response = await _client.get('/api/provider/requests');
    final data = response.data as List;
    return data.map((json) => RequestModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<RequestModel>> getOpenRequests() async {
    final response = await _client.get('/api/provider/open-requests');
    final data = response.data as List;
    return data.map((json) => RequestModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
