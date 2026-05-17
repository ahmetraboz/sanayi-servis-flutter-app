import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class ProviderOpenRequestsState {
  final bool loading;
  final String? error;
  final List<dynamic> requests;
  final int currentPage;
  final int totalPages;
  final int total;
  final String activeCategory;

  ProviderOpenRequestsState({
    this.loading = true,
    this.error,
    this.requests = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.activeCategory = 'all',
  });

  ProviderOpenRequestsState copyWith({
    bool? loading,
    String? error,
    List<dynamic>? requests,
    int? currentPage,
    int? totalPages,
    int? total,
    String? activeCategory,
  }) {
    return ProviderOpenRequestsState(
      loading: loading ?? this.loading,
      error: error,
      requests: requests ?? this.requests,
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
      final queryParams = {'page': page.toString(), 'limit': '10'};
      if (state.activeCategory != 'all') {
        queryParams['category'] = state.activeCategory;
      }

      final response = await _apiClient.get('/api/provider/open-requests', queryParameters: queryParams);
      
      final data = response.data['data'] as List<dynamic>? ?? [];
      final pagination = response.data['pagination'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        loading: false,
        requests: data,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
        total: pagination['total'] as int? ?? data.length,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Talepler yüklenirken bir hata oluştu: ${e.toString()}',
      );
    }
  }

  void onCategoryChanged(String category) {
    if (state.activeCategory == category) return;
    state = state.copyWith(activeCategory: category);
    fetchRequests(page: 1);
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      fetchRequests(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      fetchRequests(page: state.currentPage - 1);
    }
  }
}

final providerOpenRequestsProvider =
    StateNotifierProvider<ProviderOpenRequestsNotifier, ProviderOpenRequestsState>((ref) {
  return ProviderOpenRequestsNotifier(ref.watch(apiClientProvider));
});
