import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/active_job.dart';
import 'models/open_request_preview.dart';
import 'models/provider_stats.dart';

class ProviderDashboardRepository {
  final ApiClient _api;

  ProviderDashboardRepository(this._api);

  Future<ProviderStats> fetchStats() async {
    try {
      final res = await _api.get('/api/provider/stats');
      return ProviderStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'İstatistikler yüklenemedi');
    }
  }

  Future<List<ActiveJob>> fetchActiveJobs() async {
    try {
      final res = await _api.get('/api/provider/jobs');
      final jobs = (res.data['jobs'] as List? ?? [])
          .map((e) => ActiveJob.fromJson(e as Map<String, dynamic>))
          .where((j) => j.status == 'accepted' || j.status == 'in_progress')
          .take(3)
          .toList();
      return jobs;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Aktif işler yüklenemedi');
    }
  }

  Future<List<OpenRequestPreview>> fetchRecentRequests() async {
    try {
      final res = await _api.get('/api/provider/open-requests', queryParameters: {'limit': 5, 'page': 1});
      final data = res.data['data'] as List? ?? [];
      return data.map((e) => OpenRequestPreview.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Talepler yüklenemedi');
    }
  }
}

final providerDashboardRepositoryProvider = Provider<ProviderDashboardRepository>((ref) {
  return ProviderDashboardRepository(ref.read(apiClientProvider));
});
