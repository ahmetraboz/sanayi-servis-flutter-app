import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _kPageSize = 10;

class ProviderOpenRequestsState {
  final bool loading;
  final String? error;
  final List<dynamic> requests;
  final List<dynamic> _allRequests;
  final int currentPage;
  final int totalPages;
  final int total;
  final String activeCategory;

  ProviderOpenRequestsState({
    this.loading = true,
    this.error,
    this.requests = const [],
    List<dynamic> allRequests = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.activeCategory = 'all',
  }) : _allRequests = allRequests;

  ProviderOpenRequestsState copyWith({
    bool? loading,
    String? error,
    List<dynamic>? requests,
    List<dynamic>? allRequests,
    int? currentPage,
    int? totalPages,
    int? total,
    String? activeCategory,
  }) {
    return ProviderOpenRequestsState(
      loading: loading ?? this.loading,
      error: error,
      requests: requests ?? this.requests,
      allRequests: allRequests ?? _allRequests,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      activeCategory: activeCategory ?? this.activeCategory,
    );
  }
}

class ProviderOpenRequestsNotifier extends StateNotifier<ProviderOpenRequestsState> {
  final ApiClient _apiClient;

  ProviderOpenRequestsNotifier(this._apiClient) : super(ProviderOpenRequestsState()) {
    fetchRequests();
  }

  Future<void> fetchRequests({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _apiClient.get(
        '/api/provider/open-requests',
        queryParameters: {'page': '1', 'limit': '200'},
      );

      final all = response.data['data'] as List<dynamic>? ?? [];
      _applyFilter(all: all, category: state.activeCategory, page: page);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Talepler yüklenirken bir hata oluştu.',
      );
    }
  }

  void onCategoryChanged(String category) {
    if (state.activeCategory == category) return;
    _applyFilter(all: state._allRequests, category: category, page: 1);
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      _applyFilter(all: state._allRequests, category: state.activeCategory, page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      _applyFilter(all: state._allRequests, category: state.activeCategory, page: state.currentPage - 1);
    }
  }

  void _applyFilter({required List<dynamic> all, required String category, required int page}) {
    final filtered = category == 'all'
        ? all
        : all.where((r) => (r as Map<String, dynamic>)['problemCategory'] == category).toList();

    final total = filtered.length;
    final totalPages = (total / _kPageSize).ceil().clamp(1, 999);
    final safePage = page.clamp(1, totalPages);
    final offset = (safePage - 1) * _kPageSize;
    final pageData = filtered.skip(offset).take(_kPageSize).toList();

    state = state.copyWith(
      loading: false,
      error: null,
      allRequests: all,
      requests: pageData,
      currentPage: safePage,
      totalPages: totalPages,
      total: total,
      activeCategory: category,
    );
  }
}

final providerOpenRequestsProvider =
    StateNotifierProvider<ProviderOpenRequestsNotifier, ProviderOpenRequestsState>((ref) {
  return ProviderOpenRequestsNotifier(ref.watch(apiClientProvider));
});
