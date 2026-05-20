import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_polling_provider.dart';

class BadgeCounts {
  final int unreadNotifications;
  final int pendingBids;

  const BadgeCounts({this.unreadNotifications = 0, this.pendingBids = 0});
}

final badgeCountsProvider = Provider.autoDispose<BadgeCounts>((ref) {
  final polling = ref.watch(notificationPollingProvider);
  return BadgeCounts(
    unreadNotifications: polling.unreadCount,
    pendingBids: polling.pendingBids,
  );
});
