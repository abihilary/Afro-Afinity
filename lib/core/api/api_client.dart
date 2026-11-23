import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/config/api_config.dart';
import '../util/json.dart';
import 'auth_token.dart';

/// The API said no. `code` is the stable thing to branch on
/// (`api/src/lib/errors.ts`); `message` is for logs and fallbacks only.
class ApiException implements Exception {
  ApiException({required this.code, required this.message, required this.details, required this.statusCode});

  final String code;
  final String message;
  final Json details;
  final int statusCode;

  /// zod's flattened field errors, for `invalid_body`.
  Map<String, List<String>> get fieldErrors => asMap(details['fieldErrors'])
      .map((k, v) => MapEntry(k, asStringList(v)));

  @override
  String toString() => 'ApiException [$code] ($statusCode): $message';
}

/// The request never got an answer. A different screen from "the server said
/// no", so it is a different type.
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      // Campay's USSD push is slow to answer.
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Platform': defaultTargetPlatform.name,
      },
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  late final Dio _dio;

  /// One refresh at a time: when several requests 401 together (the token
  /// expired under all of them) they wait on the same refresh instead of each
  /// rotating the refresh token and invalidating the others.
  Future<String?>? _refreshing;

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = currentAccessToken();
    if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  Future<String?> _refresh() {
    return _refreshing ??= Supabase.instance.client.auth
        .refreshSession()
        .then((r) => r.session?.accessToken)
        .catchError((Object e) {
      debugPrint('Session refresh failed: $e');
      return null;
    }).whenComplete(() => _refreshing = null);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    final req = e.requestOptions;
    // 401 → refresh once → retry once. Never twice: a genuine 401 would loop.
    if (e.response?.statusCode == 401 && req.extra['isRetry'] != true && currentAccessToken() != null) {
      final token = await _refresh();
      if (token != null) {
        req.extra['isRetry'] = true;
        req.headers['Authorization'] = 'Bearer $token';
        try {
          return handler.resolve(await _dio.fetch(req));
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      }
    }
    handler.next(e);
  }

  Exception _translate(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = asMap(data['error']);
      return ApiException(
        code: asString(err['code']) ?? 'unknown_error',
        message: asString(err['message']) ?? 'Something went wrong',
        details: asMap(err['details']),
        statusCode: e.response?.statusCode ?? 500,
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('You are offline or the connection timed out.');
      default:
        if (e.response != null) {
          return ApiException(
            code: 'http_${e.response!.statusCode}',
            message: e.message ?? 'Request failed',
            details: const {},
            statusCode: e.response!.statusCode ?? 500,
          );
        }
        return NetworkException(e.message ?? 'Network error');
    }
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw _translate(e);
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));
  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send(() => _dio.post(path, data: data ?? const <String, dynamic>{}, queryParameters: _clean(query)));
  Future<dynamic> put(String path, {Object? data}) => _send(() => _dio.put(path, data: data));
  Future<dynamic> patch(String path, {Object? data}) => _send(() => _dio.patch(path, data: data));
  Future<dynamic> delete(String path, {Object? data}) => _send(() => _dio.delete(path, data: data));

  /// Typed shorthand for the common case: an object body.
  Future<Json> getJson(String path, {Map<String, dynamic>? query}) async => asMap(await get(path, query: query));
  Future<Json> postJson(String path, {Object? data}) async => asMap(await post(path, data: data));

  static Map<String, dynamic>? _clean(Map<String, dynamic>? q) =>
      q == null ? null : (Map.of(q)..removeWhere((_, v) => v == null || (v is String && v.isEmpty)));
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
