import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class NotificationItem {
  final int id;
  final String title;
  final String? message;
  final String type;
  final bool isRead;
  final String? link;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    this.message,
    required this.type,
    required this.isRead,
    this.link,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        message: j['message'] as String?,
        type: j['type'] as String? ?? 'system',
        isRead: j['isRead'] as bool? ?? false,
        link: j['link'] as String?,
        createdAt: j['createdAt'] as String? ?? '',
      );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        link: link,
        createdAt: createdAt,
      );
}

class ProviderNotificationsState {
  final bool loading;
  final String? error;
  final List<NotificationItem> notifications;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool markingAll;
  final bool clearing;

  const ProviderNotificationsState({
    this.loading = true,
    this.error,
    this.notifications = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.markingAll = false,
    this.clearing = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  ProviderNotificationsState copyWith({
    bool? loading,
    Object? error = _sentinel,
    List<NotificationItem>? notifications,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? markingAll,
    bool? clearing,
  }) {
    return ProviderNotificationsState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      markingAll: markingAll ?? this.markingAll,
      clearing: clearing ?? this.clearing,
    );
  }
}

class ProviderNotificationsNotifier extends StateNotifier<ProviderNotificationsState> {
  final ApiClient _api;

  ProviderNotificationsNotifier(this._api) : super(const ProviderNotificationsState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/notifications', queryParameters: {'page': '$page', 'limit': '20'});
      final data = (res.data['data'] as List? ?? [])
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = res.data['pagination'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        loading: false,
        notifications: data,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
        total: pagination['total'] as int? ?? data.length,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Bildirimler yüklenemedi');
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.put('/api/notifications/$id');
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    state = state.copyWith(markingAll: true);
    try {
      await _api.post('/api/notifications/mark-all-read');
      state = state.copyWith(
        markingAll: false,
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    } catch (_) {
      state = state.copyWith(markingAll: false);
    }
  }

  Future<void> clearAll() async {
    state = state.copyWith(clearing: true);
    try {
      await _api.delete('/api/notifications');
      state = state.copyWith(clearing: false, notifications: [], total: 0, totalPages: 1);
    } catch (_) {
      state = state.copyWith(clearing: false);
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) fetchNotifications(page: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) fetchNotifications(page: state.currentPage - 1);
  }
}

final providerNotificationsProvider = StateNotifierProvider.autoDispose<ProviderNotificationsNotifier, ProviderNotificationsState>(
  (ref) => ProviderNotificationsNotifier(ref.read(apiClientProvider)),
);
