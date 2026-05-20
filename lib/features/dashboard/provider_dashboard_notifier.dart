import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/active_job.dart';
import 'models/open_request_preview.dart';
import 'provider_dashboard_repository.dart';
import 'models/provider_stats.dart';

const _sentinel = Object();

class ProviderDashboardState {
  final bool loading;
  final String? error;
  final ProviderStats? stats;
  final List<ActiveJob> activeJobs;
  final List<OpenRequestPreview> recentRequests;

  const ProviderDashboardState({
    this.loading = false,
    this.error,
    this.stats,
    this.activeJobs = const [],
    this.recentRequests = const [],
  });

  ProviderDashboardState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? stats = _sentinel,
    List<ActiveJob>? activeJobs,
    List<OpenRequestPreview>? recentRequests,
  }) {
    return ProviderDashboardState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      stats: identical(stats, _sentinel) ? this.stats : stats as ProviderStats?,
      activeJobs: activeJobs ?? this.activeJobs,
      recentRequests: recentRequests ?? this.recentRequests,
    );
  }
}

class ProviderDashboardNotifier extends StateNotifier<ProviderDashboardState> {
  final ProviderDashboardRepository _repo;

  ProviderDashboardNotifier(this._repo) : super(const ProviderDashboardState()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.fetchStats(),
        _repo.fetchActiveJobs(),
        _repo.fetchRecentRequests(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        stats: results[0] as ProviderStats,
        activeJobs: results[1] as List<ActiveJob>,
        recentRequests: results[2] as List<OpenRequestPreview>,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: e is ApiException ? e.message : 'Veriler yüklenemedi',
      );
    }
  }
}

final providerDashboardProvider =
    StateNotifierProvider.autoDispose<ProviderDashboardNotifier, ProviderDashboardState>((ref) {
  return ProviderDashboardNotifier(ref.read(providerDashboardRepositoryProvider));
});
