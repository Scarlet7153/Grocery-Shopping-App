import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../utils/logger.dart'; // Import logger

class ApiClient {
  late final Dio _dio;
  final SharedPreferences? _prefs;

  ApiClient({SharedPreferences? prefs}) : _prefs = prefs {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add custom logging interceptor thay vì Dio's LogInterceptor
    if (Environment.enableLogging) {
      _dio.interceptors.add(CustomLogInterceptor());
    }

    // Add auth interceptor
    _dio.interceptors.add(AuthInterceptor(_prefs));

    // Add error handling interceptor
    _dio.interceptors.add(ErrorInterceptor());
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Custom logging interceptor sử dụng AppLogger
class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.apiRequest(
      options.method,
      '${options.baseUrl}${options.path}',
      data: options.data,
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.apiResponse(
      response.requestOptions.method,
      '${response.requestOptions.baseUrl}${response.requestOptions.path}',
      response.statusCode ?? 0,
      data: response.data,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.apiError(
      err.requestOptions.method,
      '${err.requestOptions.baseUrl}${err.requestOptions.path}',
      err,
    );
    super.onError(err, handler);
  }
}

/// Auth Interceptor to automatically add authorization headers
class AuthInterceptor extends Interceptor {
  final SharedPreferences? _prefs;
  static const String _keyAccessToken = 'auth_access_token';

  AuthInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authorization header if token exists
    if (_prefs != null) {
      final token = _prefs!.getString(_keyAccessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 unauthorized errors
    if (err.response?.statusCode == 401) {
      // Token expired or invalid - clear stored token
      _prefs?.remove(_keyAccessToken);
      AppLogger.warning('Token expired - user needs to login again');
    }
    super.onError(err, handler);
  }
}

/// Error Interceptor for consistent error handling
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      'API Error: ${err.message}',
      {
        'statusCode': err.response?.statusCode,
        'responseData': err.response?.data,
        'requestPath': err.requestOptions.path,
        'requestMethod': err.requestOptions.method,
      },
    );
    
    super.onError(err, handler);
  }
}