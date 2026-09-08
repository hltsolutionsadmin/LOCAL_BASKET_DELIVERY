import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import 'token_storage.dart';

enum Method { post, get, put, delete, patch }

class DioClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final TokenStorage _tokenStorage = TokenStorage();

  /// Bare client used only to hit the refresh endpoint, so the auth
  /// interceptor below can never recurse into itself.
  late final Dio _refreshDio;

  /// Single-flight guard: many requests can discover an expired token at the
  /// same time, but only one network refresh should actually run.
  Future<String?>? _pendingRefresh;

  DioClient(this.dio, {required this.secureStorage}) {
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _refreshDio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Proactively refresh an expired/near-expiry access token before the
        // call goes out (skip the auth calls themselves).
        if (!_isAuthEndpoint(options.path)) {
          final refreshToken = await _tokenStorage.getRefreshToken();
          final expired = await _tokenStorage.isAccessTokenExpired();
          if (expired && refreshToken != null && refreshToken.isNotEmpty) {
            await _refreshToken();
          }
        }

        final token = await _tokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $token";
        } else {
          options.headers.remove("Authorization");
        }

        log('REQUEST[${options.method}] => PATH: ${options.path} '
            '=> Request Values: ${options.queryParameters}, => HEADERS: ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        final statusCode = error.response?.statusCode;
        final errorData = error.response?.data;
        final errorMessage = errorData is Map
            ? errorData['message'] ?? 'Unknown error occurred'
            : 'Unknown error occurred';

        log('ERROR[$statusCode] => MESSAGE: $errorMessage');

        final alreadyRetried = error.requestOptions.extra['tokenRetry'] == true;

        // Reactive refresh: the access token was rejected mid-flight.
        // Some gateways answer an expired/invalid JWT with 403 rather than 401.
        final looksLikeAuthFailure = statusCode == 401 || statusCode == 403;
        if (looksLikeAuthFailure &&
            !alreadyRetried &&
            !_isAuthEndpoint(error.requestOptions.path) &&
            (await _tokenStorage.getRefreshToken())?.isNotEmpty == true) {
          final newToken = await _refreshToken();

          if (newToken != null && newToken.isNotEmpty) {
            final RequestOptions requestOptions = error.requestOptions;
            requestOptions.headers["Authorization"] = "Bearer $newToken";
            requestOptions.extra['tokenRetry'] = true;
            try {
              final response = await dio.fetch(requestOptions);
              return handler.resolve(response);
            } catch (e) {
              log('Retry after token refresh failed: $e');
              return handler.reject(error);
            }
          }
        }

        return handler.next(error);
      },
    ));
  }

  bool _isAuthEndpoint(String path) {
    return path.contains(SigninUrl) ||
        path.contains(TriggerOtp) ||
        path.contains(refreshTokenUrl);
  }

  /// Swap the (old) refresh token for a fresh access + refresh token pair.
  /// Returns the new access token, or `null` when the session can't be renewed
  /// (in which case stored tokens are cleared and the user must sign in again).
  Future<String?> _refreshToken() {
    return _pendingRefresh ??=
        _performRefresh().whenComplete(() => _pendingRefresh = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStorage.clear();
      return null;
    }

    try {
      final deviceId = await _tokenStorage.getDeviceId();
      final response = await _refreshDio.post(
        '$baseUrl$refreshTokenUrl',
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
      );

      final data = response.data;
      if (data is! Map) return null;

      final newAccessToken = (data['accessToken'] ?? data['token']) as String?;
      final newRefreshToken = (data['refreshToken'] as String?) ?? refreshToken;
      final expiresIn = data['expiresIn'];

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _tokenStorage.clear();
        return null;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresIn: expiresIn is int
            ? expiresIn
            : int.tryParse('${expiresIn ?? ''}'),
      );

      log('Access token refreshed via refresh token.');
      return newAccessToken;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      log('Token refresh failed [$code]: ${e.message}');
      // Refresh token itself is invalid / expired (30-day window elapsed).
      if (code == 401 || code == 403) {
        await _tokenStorage.clear();
      }
      return null;
    } catch (e) {
      log('Token refresh failed: $e');
      return null;
    }
  }

  Future<Response> request(
    String path, {
    Method method = Method.get,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? customBaseUrl,
  }) async {
    final Options options = Options(method: method.name.toUpperCase());
    final String url = (customBaseUrl ?? dio.options.baseUrl) + path;

    try {
      final response = await dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }
}
