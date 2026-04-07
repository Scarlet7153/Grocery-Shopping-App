import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Network configuration and Dio setup
class NetworkConfig {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectionTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logger disabled in production
    // To enable, uncomment below:
    // dio.interceptors.add(
    //   PrettyDioLogger(
    //     requestHeader: true,
    //     requestBody: false,
    //     responseBody: false,
    //     error: true,
    //   ),
    // );

    return dio;
  }
}

/// Custom Dio interceptor for authentication
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add auth token to requests
    // This will be implemented when we have auth state management
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle token refresh and retry logic
    // This will be implemented with auth bloc
    super.onError(err, handler);
  }
}
