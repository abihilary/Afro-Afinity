import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/api_config.dart';
import 'auth_token.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic> details;
  final int statusCode;

  ApiException({
    required this.code,
    required this.message,
    required this.details,
    required this.statusCode,
  });

  @override
  String toString() => 'ApiException [$code] ($statusCode): $message (details: $details)';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = currentAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final requestOptions = e.requestOptions;
            // Prevent infinite retry loop
            if (requestOptions.extra['isRetry'] == true) {
              return handler.next(e);
            }
            requestOptions.extra['isRetry'] = true;

            try {
              final response = await Supabase.instance.client.auth.refreshSession();
              final newToken = response.session?.accessToken;
              if (newToken != null) {
                requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final cloneReq = await _dio.fetch(requestOptions);
                return handler.resolve(cloneReq);
              }
            } catch (refreshError) {
              debugPrint('Session refresh failed: $refreshError');
            }
          }

          // Parse error envelope if present
          final data = e.response?.data;
          if (data is Map<String, dynamic> && data.containsKey('error')) {
            final errObj = data['error'];
            if (errObj is Map<String, dynamic>) {
              final code = errObj['code']?.toString() ?? 'unknown_error';
              final message = errObj['message']?.toString() ?? e.message ?? 'Unknown error';
              final details = errObj['details'] is Map<String, dynamic> 
                  ? errObj['details'] as Map<String, dynamic> 
                  : <String, dynamic>{};
              
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  response: e.response,
                  type: e.type,
                  error: ApiException(
                    code: code,
                    message: message,
                    details: details,
                    statusCode: e.response?.statusCode ?? 500,
                  ),
                ),
              );
            }
          }

          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                response: e.response,
                type: e.type,
                error: NetworkException('You are offline or the connection timed out.'),
              ),
            );
          }

          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is Exception) throw e.error!;
      rethrow;
    }
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is Exception) throw e.error!;
      rethrow;
    }
  }

  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is Exception) throw e.error!;
      rethrow;
    }
  }

  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is Exception) throw e.error!;
      rethrow;
    }
  }

  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      if (e.error is Exception) throw e.error!;
      rethrow;
    }
  }
}
