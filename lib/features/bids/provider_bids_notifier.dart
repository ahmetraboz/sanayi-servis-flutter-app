import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderBidsState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> bids;
  final int currentPage;
  final int totalPages;
  final int total;
  final String activeTab;
  final Map<String, int> counts;

  const ProviderBidsState({
    this.loading = true,
    this.error,
    this.bids = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.activeTab = 'all',
    this.counts = const {'all': 0, 'pending': 0, 'accepted': 0, 'rejected': 0},
  });

  ProviderBidsState copyWith({
    bool? loading,
    Object? error = _sentinel,
    List<Map<String, dynamic>>? bids,
    int? currentPage,
    int? totalPages,
    int? total,
    String? activeTab,
    Map<String, int>? counts,
  }) {
    return ProviderBidsState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      bids: bids ?? this.bids,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      activeTab: activeTab ?? this.activeTab,
      counts: counts ?? this.counts,
    );
  }
}

class ProviderBidsNotifier extends StateNotifier<ProviderBidsState> {
  final ApiClient _api;

  ProviderBidsNotifier(this._api) : super(const ProviderBidsState()) {
    fetchBids();
  }

  Future<void> fetchBids({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final params = <String, String>{'page': '$page', 'limit': '20'};
      if (state.activeTab != 'all') params['status'] = state.activeTab;

      final res = await _api.get('/api/provider/bids', queryParameters: params);
      final data = (res.data['data'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList();
      final pagination = res.data['pagination'] as Map<String, dynamic>? ?? {};
      final rawCounts = res.data['counts'] as Map<String, dynamic>? ?? const {};
      final counts = <String, int>{
        'all': (rawCounts['all'] as int?) ?? 0,
        'pending': (rawCounts['pending'] as int?) ?? 0,
        'accepted': (rawCounts['accepted'] as int?) ?? 0,
        'rejected': (rawCounts['rejected'] as int?) ?? 0,
      };

      state = state.copyWith(
        loading: false,
        bids: data,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
        total: pagination['total'] as int? ?? data.length,
        counts: counts,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Teklifler yüklenemedi');
    }
  }

  void onTabChanged(String tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
    fetchBids(page: 1);
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) fetchBids(page: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) fetchBids(page: state.currentPage - 1);
  }
}

final providerBidsProvider = StateNotifierProvider.autoDispose<ProviderBidsNotifier, ProviderBidsState>(
  (ref) => ProviderBidsNotifier(ref.read(apiClientProvider)),
);
