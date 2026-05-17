import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class BadgeCounts {
  final int unreadNotifications;
  final int pendingBids;

  const BadgeCounts({this.unreadNotifications = 0, this.pendingBids = 0});
}

final badgeCountsProvider = FutureProvider<BadgeCounts>((ref) async {
  final api = ref.read(apiClientProvider);
  try {
    final results = await Future.wait([
      api.get('/api/notifications', queryParameters: {'limit': '50', 'page': '1'}),
      api.get('/api/provider/bids', queryParameters: {'limit': '200'}),
    ]);

    final unread = (results[0].data['data'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .where((n) => !(n['isRead'] as bool? ?? false))
        .length;

    final pending = (results[1].data['data'] as List? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .where((b) => b['status'] == 'pending')
        .length;

    return BadgeCounts(unreadNotifications: unread, pendingBids: pending);
  } catch (_) {
    return const BadgeCounts();
  }
});
