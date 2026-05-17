import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

const _sentinel = Object();

class ProviderGuestBookingDetailState {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? booking;
  final Map<String, dynamic>? myResponse;
  final List<Map<String, dynamic>> updates;
  final bool submitting;
  final bool postingUpdate;
  final String? actionError;

  const ProviderGuestBookingDetailState({
    this.loading = true,
    this.error,
    this.booking,
    this.myResponse,
    this.updates = const [],
    this.submitting = false,
    this.postingUpdate = false,
    this.actionError,
  });

  String? get status => booking?['status'] as String?;
  String? get responseStatus => myResponse?['status'] as String?;
  String? get guestStatus => myResponse?['guestStatus'] as String?;

  bool get hasResponse => myResponse != null;
  bool get isQuoted => responseStatus == 'quoted';
  bool get isRejected => responseStatus == 'rejected';
  bool get guestAccepted => guestStatus == 'accepted';
  bool get isInProgress => status == 'in_progress' || status == 'accepted';
  bool get isPendingReview => status == 'pending_review';
  bool get isCompleted => status == 'completed';
  bool get canAddUpdate => guestAccepted && (isInProgress || isPendingReview);

  ProviderGuestBookingDetailState copyWith({
    bool? loading,
    Object? error = _sentinel,
    Object? booking = _sentinel,
    Object? myResponse = _sentinel,
    List<Map<String, dynamic>>? updates,
    bool? submitting,
    bool? postingUpdate,
    Object? actionError = _sentinel,
  }) {
    return ProviderGuestBookingDetailState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      booking: identical(booking, _sentinel) ? this.booking : booking as Map<String, dynamic>?,
      myResponse: identical(myResponse, _sentinel) ? this.myResponse : myResponse as Map<String, dynamic>?,
      updates: updates ?? this.updates,
      submitting: submitting ?? this.submitting,
      postingUpdate: postingUpdate ?? this.postingUpdate,
      actionError: identical(actionError, _sentinel) ? this.actionError : actionError as String?,
    );
  }
}

class ProviderGuestBookingDetailNotifier extends StateNotifier<ProviderGuestBookingDetailState> {
  final ApiClient _api;
  final int _id;

  ProviderGuestBookingDetailNotifier(this._api, this._id) : super(const ProviderGuestBookingDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.get('/api/provider/guest-bookings/$_id');
      final data = res.data as Map<String, dynamic>;
      final updatesRaw = (data['updates'] as List? ?? []).cast<Map<String, dynamic>>();
      final responseRaw = data['myResponse'] as Map<String, dynamic>?;
      state = state.copyWith(
        loading: false,
        booking: data,
        myResponse: responseRaw,
        updates: updatesRaw,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, error: e.message ?? 'Rezervasyon yüklenemedi');
    }
  }

  Future<bool> submitQuote({required double price, String? note}) async {
    state = state.copyWith(submitting: true, actionError: null);
    try {
      await _api.post('/api/provider/guest-bookings/$_id/respond', data: {
        'action': 'quote',
        'price': price,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      await loadDetail();
      state = state.copyWith(submitting: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(submitting: false, actionError: e.message ?? 'Fiyat teklifi gönderilemedi');
      return false;
    }
  }

  Future<bool> rejectBooking({String? note}) async {
    state = state.copyWith(submitting: true, actionError: null);
    try {
      await _api.post('/api/provider/guest-bookings/$_id/respond', data: {
        'action': 'reject',
        if (note != null && note.isNotEmpty) 'note': note,
      });
      await loadDetail();
      state = state.copyWith(submitting: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(submitting: false, actionError: e.message ?? 'Reddetme işlemi başarısız');
      return false;
    }
  }

  Future<bool> postUpdate({
    required String updateType,
    required String description,
    String? partsUsed,
    String? delayReason,
    int? delayEstimateDays,
    double? laborCost,
    double? partsCost,
    double? totalCost,
  }) async {
    state = state.copyWith(postingUpdate: true, actionError: null);
    try {
      final body = <String, dynamic>{
        'updateType': updateType,
        'description': description,
        if (partsUsed != null && partsUsed.isNotEmpty) 'partsUsed': partsUsed,
        if (delayReason != null && delayReason.isNotEmpty) 'delayReason': delayReason,
        if (delayEstimateDays != null) 'delayEstimateDays': delayEstimateDays,
        if (laborCost != null) 'laborCost': laborCost,
        if (partsCost != null) 'partsCost': partsCost,
        if (totalCost != null) 'totalCost': totalCost,
      };
      await _api.post('/api/provider/guest-bookings/$_id/updates', data: body);
      await loadDetail();
      state = state.copyWith(postingUpdate: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(postingUpdate: false, actionError: e.message ?? 'Güncelleme eklenemedi');
      return false;
    }
  }

  Future<bool> markInProgress() async {
    state = state.copyWith(submitting: true, actionError: null);
    try {
      await _api.post('/api/provider/guest-bookings/$_id/status', data: {'status': 'in_progress'});
      await loadDetail();
      state = state.copyWith(submitting: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(submitting: false, actionError: e.message ?? 'Durum güncellenemedi');
      return false;
    }
  }
}

final providerGuestBookingDetailProvider = StateNotifierProvider.autoDispose
    .family<ProviderGuestBookingDetailNotifier, ProviderGuestBookingDetailState, int>(
  (ref, id) => ProviderGuestBookingDetailNotifier(ref.read(apiClientProvider), id),
);
