import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_notifier.dart';

const _tokenKey = 'session_token';

// Auth paths that must not trigger logout when they receive 401
const _noLogoutPaths = {'/api/auth/login', '/api/auth/logout', '/api/auth/me'};

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient(Ref ref) {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://sanayi-uygulamasi.vercel.app',
      ),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_LogoutOn401Interceptor(ref));
    _dio.interceptors.add(_ErrorInterceptor());
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postFormData(String path, FormData formData) =>
      _dio.post(path, data: formData);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Cookie'] = 'session_token=$token';
    }
    handler.next(options);
  }
}

class _LogoutOn401Interceptor extends Interceptor {
  final Ref _ref;
  _LogoutOn401Interceptor(this._ref);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        !_noLogoutPaths.contains(err.requestOptions.path)) {
      _ref.read(authNotifierProvider.notifier).logout();
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final message = response.data is Map
          ? response.data['message'] as String? ?? 'Bir hata oluştu'
          : 'Bir hata oluştu';
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        response: response,
        type: err.type,
        message: message,
      ));
      return;
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
