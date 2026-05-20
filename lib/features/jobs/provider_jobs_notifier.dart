import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderJobsState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> jobs;
  final int currentPage;
  final int totalPages;
  final int total;

  const ProviderJobsState({
    this.loading = true,
    this.error,
    this.jobs = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  ProviderJobsState copyWith({
    bool? loading,
    Object? error = _sentinel,
    List<Map<String, dynamic>>? jobs,
    int? currentPage,
    int? totalPages,
    int? total,
  }) {
    return ProviderJobsState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      jobs: jobs ?? this.jobs,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }

  List<Map<String, dynamic>> get activeJobs =>
      jobs.where((j) => ['accepted', 'in_progress'].contains(j['status'])).toList();

  List<Map<String, dynamic>> get pendingReviewJobs =>
      jobs.where((j) => j['status'] == 'pending_review').toList();

  List<Map<String, dynamic>> get completedJobs =>
      jobs.where((j) => j['status'] == 'completed').toList();
}

class ProviderJobsNotifier extends StateNotifier<ProviderJobsState> {
  final ApiClient _api;

  ProviderJobsNotifier(this._api) : super(const ProviderJobsState()) {
    fetchJobs();
  }

  Future<void> fetchJobs({int page = 1}) async {
    if (!mounted) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/provider/jobs', queryParameters: {'page': '$page', 'limit': '15'});
      final data = (res.data['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final pagination = res.data['pagination'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        jobs: data,
        currentPage: pagination['page'] as int? ?? 1,
        totalPages: pagination['totalPages'] as int? ?? 1,
        total: pagination['total'] as int? ?? data.length,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.message ?? 'İşler yüklenemedi');
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      fetchJobs(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      fetchJobs(page: state.currentPage - 1);
    }
  }
}

final providerJobsProvider = StateNotifierProvider.autoDispose<ProviderJobsNotifier, ProviderJobsState>(
  (ref) => ProviderJobsNotifier(ref.read(apiClientProvider)),
);
