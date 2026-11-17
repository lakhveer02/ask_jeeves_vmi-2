import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/core/config/api_constants.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';

/// API Client for backend communication
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;
  // Disable verbose logging - use simple print statements instead
  // final Logger _logger = Logger();

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {ApiConstants.headerContentType: 'application/json'},
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add access token to requests
          final token = await _storage.read(ApiConstants.storageKeyAccessToken);
          if (token != null) {
            options.headers[ApiConstants.headerAuthorization] = 'Bearer $token';
          }

          // Add device ID
          final deviceId = await _storage.read(ApiConstants.storageKeyDeviceId);
          if (deviceId != null) {
            options.headers[ApiConstants.headerDeviceId] = deviceId;
          }

          // _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // _logger.e('Error: ${error.response?.statusCode} ${error.requestOptions.path}');

          // Handle 401 Unauthorized - try to refresh token
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry the original request
                final options = error.requestOptions;
                final token = await _storage.read(
                  ApiConstants.storageKeyAccessToken,
                );
                options.headers[ApiConstants.headerAuthorization] =
                    'Bearer $token';

                final response = await _dio.fetch(options);
                return handler.resolve(response);
              }
            } catch (e) {
              // debugPrint('[API] Token refresh failed: $e');
              // Clear tokens and redirect to login
              await _storage.delete(ApiConstants.storageKeyAccessToken);
              await _storage.delete(ApiConstants.storageKeyRefreshToken);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(
        ApiConstants.storageKeyRefreshToken,
      );
      if (refreshToken == null) return false;

      // Note: Refresh token endpoint not yet implemented in backend
      // For now, return false to trigger re-authentication
      // debugPrint('[API] Token refresh not implemented, user needs to re-authenticate');
      return false;
    } catch (e) {
      // debugPrint('[API] Token refresh error: $e');
      return false;
    }
  }

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout',
          statusCode: 408,
          isClientError: true,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final responseData = error.response?.data;

        // Log ALL backend error details for debugging (not just 500)
        if (statusCode >= 400) {
          debugPrint('[API] ❌ Backend Error $statusCode on ${error.requestOptions.path}');
          debugPrint('[API] Request method: ${error.requestOptions.method}');
          debugPrint('[API] Request URL: ${error.requestOptions.uri}');
          debugPrint('[API] Request data: ${error.requestOptions.data}');
          if (responseData != null) {
            debugPrint('[API] ========== BACKEND RESPONSE START ==========');
            debugPrint('[API] Response type: ${responseData.runtimeType}');
            debugPrint('[API] Response data: $responseData');
            
            // Try to extract error message from backend
            if (responseData is Map) {
              if (responseData.containsKey('detail')) {
                debugPrint('[API] ❌ Backend detail: ${responseData['detail']}');
              }
              if (responseData.containsKey('message')) {
                debugPrint('[API] ❌ Backend message: ${responseData['message']}');
              }
              if (responseData.containsKey('error')) {
                debugPrint('[API] ❌ Backend error: ${responseData['error']}');
              }
              if (responseData.containsKey('errors')) {
                debugPrint('[API] ❌ Backend errors: ${responseData['errors']}');
              }
            } else if (responseData is String) {
              debugPrint('[API] ❌ Backend string response: $responseData');
            }
            debugPrint('[API] ========== BACKEND RESPONSE END ==========');
          } else {
            debugPrint('[API] ⚠️ No response data from backend');
          }
        }

        // Use client-side error messages instead of backend errors
        String message = _getClientErrorMessage(statusCode);

        // debugPrint('[API] Bad response - Status: $statusCode, Path: ${error.requestOptions.path}');

        return ApiException(
          message: message,
          statusCode: statusCode,
          data: error.response?.data,
          isClientError: true,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: 499,
          isClientError: true,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection',
          statusCode: 503,
          isClientError: true,
        );
      default:
        return ApiException(
          message: 'Something went wrong',
          statusCode: 500,
          isClientError: true,
        );
    }
  }

  /// Get client-side error message based on status code
  String _getClientErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Session expired';
      case 403:
        return 'Access denied';
      case 404:
        return 'Not found';
      case 409:
        return 'Conflict error';
      case 422:
        return 'Invalid input';
      case 429:
        return 'Too many requests';
      case 500:
        return 'Server error';
      case 502:
        return 'Service unavailable';
      case 503:
        return 'Service unavailable';
      case 504:
        return 'Request timeout';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;
  final bool isClientError; // True if message is client-side friendly

  ApiException({
    required this.message,
    required this.statusCode,
    this.data,
    this.isClientError = false,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return ApiClient(storage);
});
