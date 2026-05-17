import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderJobsState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> jobs;

  const ProviderJobsState({
    this.loading = true,
    this.error,
    this.jobs = const [],
  });

  ProviderJobsState copyWith({
    bool? loading,
    Object? error = _sentinel,
    List<Map<String, dynamic>>? jobs,
  }) {
    return ProviderJobsState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      jobs: jobs ?? this.jobs,
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

  Future<void> fetchJobs() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/provider/jobs');
      final jobs = (res.data['jobs'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      state = state.copyWith(loading: false, jobs: jobs);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'İşler yüklenemedi');
    }
  }
}

final providerJobsProvider = StateNotifierProvider.autoDispose<ProviderJobsNotifier, ProviderJobsState>(
  (ref) => ProviderJobsNotifier(ref.read(apiClientProvider)),
);
