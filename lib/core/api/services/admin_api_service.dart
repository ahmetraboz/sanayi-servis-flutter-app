import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/request_model.dart';
import '../../../shared/models/bid_model.dart';
import '../../../shared/models/guest_booking_model.dart';
import '../../../shared/models/service_model.dart';
import '../../../shared/models/provider_model.dart';

final adminApiProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(apiClientProvider));
});

class AdminApiService {
  final ApiClient _client;

  AdminApiService(this._client);

  Future<List<UserModel>> getUsers() async {
    final response = await _client.get('/api/admin/users');
    final data = response.data as List;
    return data.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<RequestModel>> getRequests() async {
    final response = await _client.get('/api/admin/requests');
    final data = response.data as List;
    return data.map((json) => RequestModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<BidModel>> getBids() async {
    final response = await _client.get('/api/admin/bids');
    final data = response.data as List;
    return data.map((json) => BidModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<dynamic>> getReviews() async {
    final response = await _client.get('/api/admin/reviews');
    return response.data as List;
  }

  Future<List<GuestBookingModel>> getGuestBookings() async {
    final response = await _client.get('/api/admin/guest-bookings');
    final data = response.data as List;
    return data.map((json) => GuestBookingModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ServiceModel>> getServices() async {
    final response = await _client.get('/api/admin/services');
    final data = response.data as List;
    return data.map((json) => ServiceModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getServiceDetail(int id) async {
    final response = await _client.get('/api/admin/services/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateServiceStatus(int id, String status) async {
    await _client.put('/api/service-profile/$id/status', data: {'status': status});
  }

  Future<void> deleteUser(int id) async {
    await _client.delete('/api/admin/users/$id');
  }

  Future<List<ProviderModel>> getProviders() async {
    final response = await _client.get('/api/public/providers', queryParameters: {'limit': '100'});
    final data = response.data as Map<String, dynamic>;
    final list = data['providers'] as List;
    return list.map((json) => ProviderModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<dynamic>> getActivity() async {
    final response = await _client.get('/api/admin/activity');
    return response.data as List;
  }
}
