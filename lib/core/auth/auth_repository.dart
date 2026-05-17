import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../../shared/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<UserModel> login(String email, String password) async {
    try {
      final res = await _api.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      // Server sets HttpOnly cookie; store any token from headers if needed
      final setCookie = res.headers.value('set-cookie');
      if (setCookie != null) {
        final match = RegExp(r'session_token=([^;]+)').firstMatch(setCookie);
        if (match != null) await _api.saveToken(match.group(1)!);
      }
      return user;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'E-posta veya şifre hatalı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    Map<String, dynamic>? vehicle,
    Map<String, dynamic>? serviceProfile,
  }) async {
    try {
      final res = await _api.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        if (vehicle != null) 'vehicle': vehicle,
        if (serviceProfile != null) ...serviceProfile,
      });
      final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      final setCookie = res.headers.value('set-cookie');
      if (setCookie != null) {
        final match = RegExp(r'session_token=([^;]+)').firstMatch(setCookie);
        if (match != null) await _api.saveToken(match.group(1)!);
      }
      return user;
    } on DioException catch (e) {
      throw ApiException(
        e.message ?? 'Kayıt sırasında bir hata oluştu',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } finally {
      await _api.deleteToken();
    }
  }

  Future<UserModel?> getMe() async {
    try {
      final res = await _api.get('/api/auth/me');
      return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
