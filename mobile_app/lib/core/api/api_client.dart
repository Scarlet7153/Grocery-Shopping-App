import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_error.dart';
import 'api_routes.dart';
import '../network/network_config.dart';
import 'token_storage.dart';

/// Reusable API client: base URL, JWT attachment, global error handling.
/// Compatible with Flutter Web and mobile.
class ApiClient {
  ApiClient._() {
    _dio = NetworkConfig.createDio();
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.interceptors.add(_AuthInterceptor(_tokenStorage));
    _dio.interceptors.add(_ErrorInterceptor());
  }

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  Dio get dio => _dio;

  /// Use this to attach token manually (e.g. after login) so subsequent requests use it.
  Future<void> setAccessToken(String? token) async {
    await _tokenStorage.setAccessToken(token);
  }

  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  Future<void> clearTokens() => _tokenStorage.clear();

  /// GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  /// POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
}

/// Attaches JWT from [TokenStorage] to outgoing requests.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Converts Dio errors to [ApiException].
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _fromDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        response: err.response,
        type: err.type,
      ),
    );
  }

  ApiException _fromDioException(DioException err) {
    final statusCode = err.response?.statusCode;
    String message = err.message ?? 'Lỗi kết nối';
    String? serverMessage;

    if (err.response?.data is Map<String, dynamic>) {
      final data = err.response!.data as Map<String, dynamic>;
      serverMessage = data['message'] as String? ?? data['error'] as String?;
    }

    if (statusCode != null) {
      if (statusCode == 401) message = 'Phiên đăng nhập hết hạn';
      else if (statusCode == 403) message = 'Không có quyền truy cập';
      else if (statusCode >= 500) message = 'Lỗi máy chủ, vui lòng thử lại';
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      serverMessage: serverMessage,
      originalError: err,
    );
  }
}
