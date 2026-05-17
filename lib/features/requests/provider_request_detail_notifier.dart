import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderRequestDetailState {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? request;
  final Map<String, dynamic>? acceptedBid;
  final List<Map<String, dynamic>> updates;
  final Map<String, dynamic>? additionalInfo;
  final bool submittingBid;
  final bool requestingInfo;
  final bool postingUpdate;
  final bool dismissing;
  final bool completing;
  final String? actionError;

  const ProviderRequestDetailState({
    this.loading = false,
    this.error,
    this.request,
    this.acceptedBid,
    this.updates = const [],
    this.additionalInfo,
    this.submittingBid = false,
    this.requestingInfo = false,
    this.postingUpdate = false,
    this.dismissing = false,
    this.completing = false,
    this.actionError,
  });

  ProviderRequestDetailState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? request = _sentinel,
    Object? acceptedBid = _sentinel,
    List<Map<String, dynamic>>? updates,
    Object? additionalInfo = _sentinel,
    bool? submittingBid,
    bool? requestingInfo,
    bool? postingUpdate,
    bool? dismissing,
    bool? completing,
    Object? actionError = _sentinel,
  }) {
    return ProviderRequestDetailState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      request: identical(request, _sentinel) ? this.request : request as Map<String, dynamic>?,
      acceptedBid: identical(acceptedBid, _sentinel) ? this.acceptedBid : acceptedBid as Map<String, dynamic>?,
      updates: updates ?? this.updates,
      additionalInfo: identical(additionalInfo, _sentinel) ? this.additionalInfo : additionalInfo as Map<String, dynamic>?,
      submittingBid: submittingBid ?? this.submittingBid,
      requestingInfo: requestingInfo ?? this.requestingInfo,
      postingUpdate: postingUpdate ?? this.postingUpdate,
      dismissing: dismissing ?? this.dismissing,
      completing: completing ?? this.completing,
      actionError: identical(actionError, _sentinel) ? this.actionError : actionError as String?,
    );
  }

  String? get status => request?['status'] as String?;
  bool get canBid => ['open', 'bidding', 'info_requested', 'info_provided'].contains(status);
  bool get canRequestInfo => ['open', 'bidding'].contains(status);
  bool get canUpdate => ['accepted', 'in_progress'].contains(status) && acceptedBid != null;
  bool get canComplete => canUpdate;
  bool get isInfoRequested => status == 'info_requested';
  bool get isInfoProvided => status == 'info_provided';
  bool get isPendingReview => status == 'pending_review';
  bool get isCompleted => status == 'completed';
}

class ProviderRequestDetailNotifier extends StateNotifier<ProviderRequestDetailState> {
  final ApiClient _api;
  final int requestId;

  ProviderRequestDetailNotifier(this._api, this.requestId)
      : super(const ProviderRequestDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/provider/requests/$requestId');
      final data = res.data as Map<String, dynamic>;
      final request = data['request'] as Map<String, dynamic>;
      final acceptedBid = data['acceptedBid'] as Map<String, dynamic>?;
      final updates = (data['updates'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();

      Map<String, dynamic>? additionalInfo;
      final status = request['status'] as String?;
      if (status == 'info_provided' || status == 'info_requested') {
        try {
          final infoRes = await _api.get('/api/requests/$requestId/additional-info');
          additionalInfo = (infoRes.data as Map<String, dynamic>)['additionalInfo'] as Map<String, dynamic>?;
        } catch (_) {}
      }

      state = state.copyWith(
        loading: false,
        request: request,
        acceptedBid: acceptedBid,
        updates: updates,
        additionalInfo: additionalInfo,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Talep yüklenemedi');
    }
  }

  Future<bool> submitBid({
    required num price,
    String? description,
    String? estimatedDuration,
  }) async {
    state = state.copyWith(submittingBid: true, actionError: null);
    try {
      await _api.post('/api/provider/bids', data: {
        'requestId': requestId,
        'price': price,
        if (description != null && description.isNotEmpty) 'description': description,
        if (estimatedDuration != null && estimatedDuration.isNotEmpty) 'estimatedDuration': estimatedDuration,
      });
      state = state.copyWith(submittingBid: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(submittingBid: false, actionError: e.message ?? 'Teklif gönderilemedi');
      return false;
    }
  }

  Future<bool> requestInfo(Map<String, dynamic> infoData) async {
    state = state.copyWith(requestingInfo: true, actionError: null);
    try {
      await _api.post('/api/provider/requests/$requestId/request-info', data: infoData);
      state = state.copyWith(requestingInfo: false);
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(requestingInfo: false, actionError: e.message ?? 'Ek bilgi talebi gönderilemedi');
      return false;
    }
  }

  Future<bool> postUpdate(Map<String, dynamic> updateData) async {
    state = state.copyWith(postingUpdate: true, actionError: null);
    try {
      await _api.post('/api/provider/requests/$requestId/updates', data: updateData);
      state = state.copyWith(postingUpdate: false);
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(postingUpdate: false, actionError: e.message ?? 'Güncelleme gönderilemedi');
      return false;
    }
  }

  Future<bool> dismissRequest() async {
    state = state.copyWith(dismissing: true, actionError: null);
    try {
      await _api.post('/api/provider/requests/$requestId/dismiss');
      state = state.copyWith(dismissing: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(dismissing: false, actionError: e.message ?? 'İşlem başarısız');
      return false;
    }
  }

  Future<bool> completeJob({
    required String workDone,
    String? partsUsed,
    num? laborCost,
    num? partsCost,
    num? totalCost,
  }) async {
    state = state.copyWith(completing: true, actionError: null);
    try {
      await _api.post('/api/provider/requests/$requestId/complete', data: {
        'workDone': workDone,
        if (partsUsed != null && partsUsed.isNotEmpty) 'partsUsed': partsUsed,
        if (laborCost != null) 'laborCost': laborCost,
        if (partsCost != null) 'partsCost': partsCost,
        if (totalCost != null) 'totalCost': totalCost,
      });
      state = state.copyWith(completing: false);
      await loadDetail();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(completing: false, actionError: e.message ?? 'İş tamamlanamadı');
      return false;
    }
  }
}

final providerRequestDetailProvider = StateNotifierProvider.autoDispose
    .family<ProviderRequestDetailNotifier, ProviderRequestDetailState, int>(
  (ref, id) => ProviderRequestDetailNotifier(ref.read(apiClientProvider), id),
);
