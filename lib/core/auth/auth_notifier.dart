import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import '../../shared/models/user_model.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  int _sessionVersion = 0;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final myVersion = _sessionVersion;
    final user = await _repo.getMe();
    if (_sessionVersion == myVersion) {
      state = AsyncValue.data(user);
    }
  }

  Future<void> login(String email, String password) async {
    _sessionVersion++;
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    Map<String, dynamic>? vehicle,
    Map<String, dynamic>? serviceProfile,
  }) async {
    _sessionVersion++;
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        vehicle: vehicle,
        serviceProfile: serviceProfile,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    _sessionVersion++;
    try {
      await _repo.logout();
    } finally {
      state = const AsyncValue.data(null);
    }
  }

  UserModel? get currentUser => state.valueOrNull;
}
