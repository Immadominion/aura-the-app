import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';

/// Structured exception thrown by [ApiClient] when the backend returns a
/// non-2xx response we want callers to react to.
///
/// `code` is the backend's machine-readable identifier (e.g.
/// `DAILY_LIMIT_REACHED`, `UNSUPPORTED_AUDIO_TYPE`). `message` is
/// safe-to-display human text. `statusCode` is the raw HTTP status.
class ApiException implements Exception {
  final int statusCode;
  final String? code;
  final String message;
  final Map<String, dynamic>? raw;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.raw,
  });

  bool get isAuth => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
  bool get isSessionRevoked =>
      statusCode == 401 &&
      (message.toLowerCase().contains('revoked') ||
          message.toLowerCase().contains('token version'));

  @override
  String toString() =>
      'ApiException($statusCode${code != null ? " $code" : ""}): $message';
}

/// Stream of "session revoked" events. Listen to this from auth controllers
/// to force a sign-out + redirect to the login screen when the backend
/// invalidates the user's session (e.g. after `/auth/logout` from another
/// device).
final sessionRevokedStreamProvider = StreamProvider<void>((ref) {
  final controller = ref.read(_sessionRevokedControllerProvider);
  return controller.stream;
});

/// Internal controller used by [ApiClient] to broadcast revocation events.
final _sessionRevokedControllerProvider = Provider<StreamController<void>>((
  ref,
) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// Central Dio-based HTTP client for the Aura backend.
///
/// Handles:
/// - Base URL configuration via EnvConfig (dev/staging/prod)
/// - JWT injection via interceptor
/// - Automatic token refresh on 401
/// - Structured error handling
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  final StreamController<void>? _sessionRevokedSink;

  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;

  ApiClient({
    String? baseUrl,
    FlutterSecureStorage? storage,
    StreamController<void>? sessionRevokedSink,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _sessionRevokedSink = sessionRevokedSink {
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
        // Treat any 4xx/5xx as Dio errors so the interceptor can normalise
        // them into ApiException; this lets callers catch a single type.
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      _ErrorNormaliser(),
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

  /// Internal — fire when the backend rejects our refresh token. Listeners
  /// (router redirect, auth controller) react by signing the user out.
  void _notifySessionRevoked() {
    if (_sessionRevokedSink != null && !_sessionRevokedSink.isClosed) {
      _sessionRevokedSink.add(null);
    }
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
    final isAuthCall = err.requestOptions.path.contains('/auth/');
    if (err.response?.statusCode == 401 &&
        _client._refreshToken != null &&
        !isAuthCall) {
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
      } else {
        // Refresh failed — session is dead. Notify listeners so the UI
        // can route back to the sign-in screen.
        _client._notifySessionRevoked();
      }
    }
    handler.next(err);
  }
}

/// Normalises Dio errors into [ApiException] so callers see a single
/// structured exception type instead of having to dig into Dio internals.
class _ErrorNormaliser extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode ?? 0;
    final data = err.response?.data;
    String message = err.message ?? 'Request failed';
    String? code;
    Map<String, dynamic>? raw;

    if (data is Map<String, dynamic>) {
      raw = data;
      // Backend shapes:
      //   { error: { message, code? } }   (createApiError)
      //   { error: 'CODE', message: '…' } (ai routes)
      //   { message: '…' }                (rate-limiter, zValidator)
      final errField = data['error'];
      if (errField is Map<String, dynamic>) {
        message = (errField['message'] as String?) ?? message;
        code = errField['code'] as String?;
      } else if (errField is String) {
        code = errField;
        message = (data['message'] as String?) ?? message;
      } else if (data['message'] is String) {
        message = data['message'] as String;
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    final apiErr = ApiException(
      statusCode: status,
      code: code,
      message: message,
      raw: raw,
    );

    // Re-wrap the Dio error so callers that catch DioException still work,
    // but the underlying `error` field carries our structured exception.
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiErr,
        message: apiErr.message,
      ),
    );
  }
}

/// ApiClient Riverpod provider (singleton).
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    sessionRevokedSink: ref.read(_sessionRevokedControllerProvider),
  );
});
