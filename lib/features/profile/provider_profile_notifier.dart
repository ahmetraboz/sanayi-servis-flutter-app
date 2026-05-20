import 'dart:convert';
import 'dart:io';

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
  final bool uploadingPhoto;
  final bool uploadingLogo;

  const ProviderProfileState({
    this.loading = true,
    this.error,
    this.profile,
    this.saving = false,
    this.saveError,
    this.saveSuccess = false,
    this.uploadingPhoto = false,
    this.uploadingLogo = false,
  });

  ProviderProfileState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? profile = _sentinel,
    bool? saving,
    Object? saveError = _sentinel,
    bool? saveSuccess,
    bool? uploadingPhoto,
    bool? uploadingLogo,
  }) {
    return ProviderProfileState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      profile: identical(profile, _sentinel) ? this.profile : profile as Map<String, dynamic>?,
      saving: saving ?? this.saving,
      saveError: identical(saveError, _sentinel) ? this.saveError : saveError as String?,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      uploadingPhoto: uploadingPhoto ?? this.uploadingPhoto,
      uploadingLogo: uploadingLogo ?? this.uploadingLogo,
    );
  }

  String? get approvalStatus => profile?['approvalStatus'] as String? ?? profile?['status'] as String?;

  List<String> get photos {
    final raw = profile?['photos'] as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
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

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      await _api.put('/api/profile/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map<String, dynamic> ? data['statusMessage'] as String? : null;
      return msg ?? e.message ?? 'Şifre değiştirilemedi';
    }
  }

  Future<String?> uploadPhoto(File file) async {
    state = state.copyWith(uploadingPhoto: true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });
      final res = await _api.postFormData('/api/upload', formData);
      final url = (res.data as Map<String, dynamic>)['url'] as String;
      final updated = [...state.photos, url];
      await _api.put('/api/service-profile', data: {'photos': jsonEncode(updated)});
      state = state.copyWith(uploadingPhoto: false);
      await loadProfile();
      return url;
    } on DioException catch (_) {
      state = state.copyWith(uploadingPhoto: false);
      return null;
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> uploadLogo(File file) async {
    state = state.copyWith(uploadingLogo: true);
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });
      await _api.postFormData('/api/service-profile/logo', formData);
      await loadProfile();
      state = state.copyWith(uploadingLogo: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(uploadingLogo: false);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      if (status == 429 && data is Map<String, dynamic>) {
        final daysLeft = data['data']?['daysLeft'] ?? data['daysLeft'];
        if (daysLeft != null) {
          return 'Logo $daysLeft gün sonra güncellenebilir';
        }
      }
      final msg = data is Map<String, dynamic> ? data['statusMessage'] as String? : null;
      return msg ?? 'Logo yüklenemedi';
    }
  }

  Future<void> removePhoto(String url) async {
    final updated = state.photos.where((p) => p != url).toList();
    await _api.put('/api/service-profile', data: {'photos': jsonEncode(updated)});
    await loadProfile();
  }
}

final providerProfileProvider = StateNotifierProvider.autoDispose<ProviderProfileNotifier, ProviderProfileState>(
  (ref) => ProviderProfileNotifier(ref.read(apiClientProvider)),
);
