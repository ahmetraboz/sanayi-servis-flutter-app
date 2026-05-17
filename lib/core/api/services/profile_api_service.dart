import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../../../shared/models/user_model.dart';

final profileApiProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.watch(apiClientProvider));
});

class ProfileApiService {
  final ApiClient _client;

  ProfileApiService(this._client);

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put('/api/profile', data: data);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
