import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderProfileState {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? profile;
  final bool saving;
  final String? saveError;
  final bool saveSuccess;

  const ProviderProfileState({
    this.loading = true,
    this.error,
    this.profile,
    this.saving = false,
    this.saveError,
    this.saveSuccess = false,
  });

  ProviderProfileState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? profile = _sentinel,
    bool? saving,
    Object? saveError = _sentinel,
    bool? saveSuccess,
  }) {
    return ProviderProfileState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      profile: identical(profile, _sentinel) ? this.profile : profile as Map<String, dynamic>?,
      saving: saving ?? this.saving,
      saveError: identical(saveError, _sentinel) ? this.saveError : saveError as String?,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }

  String? get approvalStatus => profile?['approvalStatus'] as String? ?? profile?['status'] as String?;
}

class ProviderProfileNotifier extends StateNotifier<ProviderProfileState> {
  final ApiClient _api;

  ProviderProfileNotifier(this._api) : super(const ProviderProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/service-profile');
      final profile = (res.data as Map<String, dynamic>)['profile'] as Map<String, dynamic>;
      state = state.copyWith(loading: false, profile: profile);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Profil yüklenemedi');
    }
  }

  Future<bool> saveProfile(Map<String, String?> formData) async {
    state = state.copyWith(saving: true, saveError: null, saveSuccess: false);
    try {
      final body = {for (final e in formData.entries) if (e.value != null && e.value!.isNotEmpty) e.key: e.value};
      await _api.put('/api/service-profile', data: body);
      state = state.copyWith(saving: false, saveSuccess: true);
      await loadProfile();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, saveError: e.message ?? 'Profil kaydedilemedi');
      return false;
    }
  }
}

final providerProfileProvider = StateNotifierProvider.autoDispose<ProviderProfileNotifier, ProviderProfileState>(
  (ref) => ProviderProfileNotifier(ref.read(apiClientProvider)),
);
