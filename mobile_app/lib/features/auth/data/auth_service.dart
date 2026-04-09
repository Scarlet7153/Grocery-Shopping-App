import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../core/api/api_routes.dart';
import 'auth_model.dart';

/// Auth API: login, register. Token is stored via [ApiClient] and attached to requests.
class AuthService {
  AuthService() : _client = ApiClient();

  final ApiClient _client;

  /// Login with phone and password. On success, token is saved and used by [ApiClient].
  Future<AuthResponse> login(String phoneNumber, String password) async {
    try {
      final body = AuthLoginRequest(
        phoneNumber: phoneNumber,
        password: password,
      );
      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.login,
        data: body.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi trống');
      }
      final auth = AuthResponse.fromJson(data);
      await _client.setAccessToken(auth.token);
      return auth;
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Lỗi đăng nhập');
    }
  }

  /// Register new account. Optionally login after by calling [login].
  Future<AuthResponse> register(AuthRegisterRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiRoutes.register,
        data: request.toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Phản hồi trống');
      }
      final auth = AuthResponse.fromJson(data);
      if (auth.token.isNotEmpty) await _client.setAccessToken(auth.token);
      return auth;
    } on DioException catch (e) {
      throw e.error is ApiException
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Lỗi đăng ký');
    }
  }

  /// Clear stored tokens (logout).
  Future<void> logout() async {
    await _client.clearTokens();
  }
}
