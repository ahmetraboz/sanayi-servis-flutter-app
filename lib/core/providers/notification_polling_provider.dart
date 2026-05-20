import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/provider_notifications_notifier.dart';
import '../api/api_client.dart';

class NotificationPollingState {
  final int unreadCount;
  final int pendingBids;
  final List<NotificationItem> pendingBanners;

  const NotificationPollingState({
    this.unreadCount = 0,
    this.pendingBids = 0,
    this.pendingBanners = const [],
  });

  NotificationPollingState copyWith({
    int? unreadCount,
    int? pendingBids,
    List<NotificationItem>? pendingBanners,
  }) {
    return NotificationPollingState(
      unreadCount: unreadCount ?? this.unreadCount,
      pendingBids: pendingBids ?? this.pendingBids,
      pendingBanners: pendingBanners ?? this.pendingBanners,
    );
  }
}

class NotificationPollingNotifier
    extends StateNotifier<NotificationPollingState> {
  final ApiClient _api;
  Timer? _timer;
  int _highWaterMarkId = 0;
  bool _initialized = false;

  NotificationPollingNotifier(this._api)
      : super(const NotificationPollingState()) {
    _poll(isInitial: true);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  Future<void> _poll({bool isInitial = false}) async {
    if (!mounted) return;
    try {
      final results = await Future.wait([
        _api.get('/api/notifications',
            queryParameters: {'page': '1', 'limit': '20'}),
        _api.get('/api/provider/bids',
            queryParameters: {'limit': '200', 'page': '1'}),
      ]);

      if (!mounted) return;

      final notifData = (results[0].data['data'] as List? ?? [])
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final unreadCount = notifData.where((n) => !n.isRead).length;

      final pendingBids = (results[1].data['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .where((b) => b['status'] == 'pending')
          .length;

      if (!_initialized) {
        if (notifData.isNotEmpty) {
          _highWaterMarkId = notifData.map((n) => n.id).reduce(max);
        }
        _initialized = true;
        state = state.copyWith(
            unreadCount: unreadCount, pendingBids: pendingBids);
        return;
      }

      final newNotifs = notifData
          .where((n) => !n.isRead && n.id > _highWaterMarkId)
          .toList();

      if (newNotifs.isNotEmpty) {
        _highWaterMarkId = newNotifs.map((n) => n.id).reduce(max);
      }

      state = state.copyWith(
        unreadCount: unreadCount,
        pendingBids: pendingBids,
        pendingBanners: newNotifs.isNotEmpty
            ? [...state.pendingBanners, ...newNotifs]
            : state.pendingBanners,
      );
    } on DioException catch (_) {
      // polling sırasında ağ hatası → sessizce geç
    }
  }

  void consumeBanner() {
    if (state.pendingBanners.isEmpty) return;
    state = state.copyWith(
        pendingBanners: state.pendingBanners.sublist(1));
  }

  Future<void> refresh() => _poll();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final notificationPollingProvider = StateNotifierProvider.autoDispose<
    NotificationPollingNotifier, NotificationPollingState>(
  (ref) => NotificationPollingNotifier(ref.read(apiClientProvider)),
);
