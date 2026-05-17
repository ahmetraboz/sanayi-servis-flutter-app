import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderGuestBookingsState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> bookings;
  final int currentPage;
  final int totalPages;
  final int total;

  const ProviderGuestBookingsState({
    this.loading = true,
    this.error,
    this.bookings = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  ProviderGuestBookingsState copyWith({
    bool? loading,
    Object? error = _sentinel,
    List<Map<String, dynamic>>? bookings,
    int? currentPage,
    int? totalPages,
    int? total,
  }) {
    return ProviderGuestBookingsState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      bookings: bookings ?? this.bookings,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }
}

class ProviderGuestBookingsNotifier extends StateNotifier<ProviderGuestBookingsState> {
  final ApiClient _api;

  ProviderGuestBookingsNotifier(this._api) : super(const ProviderGuestBookingsState()) {
    fetchBookings();
  }

  Future<void> fetchBookings({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/provider/guest-bookings', queryParameters: {'page': '$page', 'limit': '20'});
      final data = (res.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
      final pagination = res.data['pagination'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        loading: false,
        bookings: data,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
        total: pagination['total'] as int? ?? data.length,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Misafir rezervasyonları yüklenemedi');
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) fetchBookings(page: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) fetchBookings(page: state.currentPage - 1);
  }
}

final providerGuestBookingsProvider =
    StateNotifierProvider.autoDispose<ProviderGuestBookingsNotifier, ProviderGuestBookingsState>(
  (ref) => ProviderGuestBookingsNotifier(ref.read(apiClientProvider)),
);
