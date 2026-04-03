import 'package:dio/dio.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

class CustomerAuthRepository {
  Future<bool> login(
    String phone,
    String password,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'phoneNumber': phone,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final token = (data['data']?['token'] ?? '') as String;
        if (token.isNotEmpty) {
          AuthSession.token = token;
          await _loadProfile();
        }
        return true;
      }
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Đăng nhập thất bại');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Không thể kết nối đến máy chủ');
    } catch (_) {
      throw AuthException('Đăng nhập thất bại');
    }
    return false;
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String address,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
          'fullName': fullName,
          'role': 'CUSTOMER',
          'address': address,
        },
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final token = (data['data']?['token'] ?? '') as String;
        if (token.isNotEmpty) {
          AuthSession.token = token;
          await _loadProfile();
        }
        return true;
      }
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Đăng ký thất bại');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Không thể kết nối đến máy chủ');
    } catch (_) {
      throw AuthException('Đăng ký thất bại');
    }
    return false;
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final profile = data['data'] as Map;
        AuthSession.fullName = (profile['fullName'] ?? '').toString();
        AuthSession.address = (profile['address'] ?? '').toString();
        AuthSession.phoneNumber = (profile['phoneNumber'] ?? '').toString();
      }
    } catch (_) {
      // ignore profile fetch errors
    }
  }
}
