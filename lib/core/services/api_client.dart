import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';

/// Central Dio-based HTTP client for the Sage backend.
///
/// Handles:
/// - Base URL configuration via EnvConfig (dev/staging/prod)
/// - JWT injection via interceptor
/// - Automatic token refresh on 401
/// - Structured error handling
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  ApiClient({String? baseUrl, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    final effectiveBaseUrl = baseUrl ?? EnvConfig.apiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: EnvConfig.apiConnectTimeout,
        receiveTimeout: EnvConfig.apiReceiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
    ]);
  }

  Dio get dio => _dio;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null;

  /// Load stored tokens on app start.
  Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
  }

  /// Store tokens after auth.
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  /// Clear tokens on logout.
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  /// Attempt to refresh the access token using the stored refresh token.
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null || _isRefreshing) return false;
    _isRefreshing = true;

    try {
      // Use a separate Dio instance to avoid interceptor loops.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await setTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      // Refresh failed — user needs to re-authenticate.
      await clearTokens();
    } finally {
      _isRefreshing = false;
    }
    return false;
  }

  // ── Convenience request methods ──

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {Object? data, Options? options}) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}

/// Interceptor that injects JWT and handles 401 auto-refresh.
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_client._accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${_client._accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _client._refreshToken != null) {
      final refreshed = await _client.refreshAccessToken();
      if (refreshed) {
        // Retry the original request with the new token.
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${_client._accessToken}';
        try {
          final response = await _client._dio.fetch(opts);
          return handler.resolve(response);
        } catch (retryErr) {
          // Retry failed too — propagate.
        }
      }
    }
    handler.next(err);
  }
}

/// ApiClient Riverpod provider (singleton).
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
