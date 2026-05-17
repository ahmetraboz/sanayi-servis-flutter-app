import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/router.dart';

typedef PaginationKey = ({String path, int limit});

class PaginationState {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationState({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;

  PaginationState copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return PaginationState(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class PaginationNotifier extends StateNotifier<PaginationState> {
  final Ref _ref;
  final String _path;

  // Non-page query params (e.g. status filter) preserved across page changes
  Map<String, String> _extraParams = {};

  PaginationNotifier(
    this._ref, {
    required String path,
    required int limit,
    Uri? initialUri,
  })  : _path = path,
        super(PaginationState(
          page: int.tryParse(initialUri?.queryParameters['page'] ?? '') ?? 1,
          limit: limit,
        ));

  /// Call this after every API response to keep state in sync with the server.
  void updateFromResponse(Map<String, dynamic> pagination) {
    state = state.copyWith(
      page: pagination['page'] as int? ?? state.page,
      limit: pagination['limit'] as int? ?? state.limit,
      total: pagination['total'] as int? ?? state.total,
      totalPages: pagination['totalPages'] as int? ?? state.totalPages,
    );
  }

  /// Set additional query parameters that persist across page changes.
  /// Call this when a filter changes (before triggering a fetch).
  void setExtraParams(Map<String, String> params) {
    _extraParams = params;
  }

  /// Navigate to a specific page, updating state and URL.
  void goToPage(int page) {
    if (page < 1 || (state.totalPages > 0 && page > state.totalPages)) return;
    state = state.copyWith(page: page);
    _syncUrl(page);
  }

  void nextPage() {
    if (state.hasNextPage) goToPage(state.page + 1);
  }

  void prevPage() {
    if (state.hasPrevPage) goToPage(state.page - 1);
  }

  /// Read the current page from a URI (used when restoring state from deep link).
  void syncFromUri(Uri uri) {
    final page = int.tryParse(uri.queryParameters['page'] ?? '') ?? 1;
    if (page != state.page) {
      state = state.copyWith(page: page);
    }
  }

  void _syncUrl(int page) {
    final params = <String, String>{
      ..._extraParams,
      if (page > 1) 'page': '$page',
    };
    final uri = Uri(path: _path, queryParameters: params.isEmpty ? null : params);
    _ref.read(routerProvider).go(uri.toString());
  }
}

final paginationProvider = StateNotifierProvider.autoDispose
    .family<PaginationNotifier, PaginationState, PaginationKey>(
  (ref, key) => PaginationNotifier(ref, path: key.path, limit: key.limit),
);
