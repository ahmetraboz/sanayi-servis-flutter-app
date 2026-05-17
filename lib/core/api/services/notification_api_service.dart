import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../../../shared/models/notification_model.dart';

final notificationApiProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(apiClientProvider));
});

class NotificationApiService {
  final ApiClient _client;

  NotificationApiService(this._client);

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client.get('/api/notifications');
    final data = response.data as List;
    return data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(int id) async {
    await _client.put('/api/notifications/$id');
  }

  Future<void> markAllAsRead() async {
    await _client.post('/api/notifications/mark-all-read');
  }

  Future<void> deleteNotification(int id) async {
    await _client.delete('/api/notifications/$id');
  }
}
