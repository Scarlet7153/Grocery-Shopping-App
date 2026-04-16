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
  Future<bool> login(String phone, String password) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {'phoneNumber': phone, 'password': password},
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final token = (data['data']?['token'] ?? '') as String;
        if (token.isNotEmpty) {
          await AuthSession.persistToken(token);
          await _loadProfile();
        }
        return true;
      }
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Login failed');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Cannot connect to server');
    } catch (_) {
      throw AuthException('Login failed');
    }
    // return false;
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
          await AuthSession.persistToken(token);
          await _loadProfile();
        }
        return true;
      }
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Sign up failed');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw AuthException(data['message'].toString());
      }
      throw AuthException('Cannot connect to server');
    } catch (_) {
      throw AuthException('Sign up failed');
    }
    // return false;
  }

  Future<bool> tryRestoreSession() async {
    await AuthSession.restore();
    final token = AuthSession.token;

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await ApiClient.dio.get('/auth/me');
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final profile = data['data'] as Map;
        _applyProfile(profile);
        return true;
      }
      await AuthSession.clearPersistedToken();
      AuthSession.clear();
      return false;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        await AuthSession.clearPersistedToken();
        AuthSession.clear();
        return false;
      }
      // Keep existing token for transient failures (timeout/offline/server down).
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        _applyProfile(data['data'] as Map);
      }
    } catch (_) {
      // ignore profile fetch errors
    }
  }

  void _applyProfile(Map profile) {
    AuthSession.fullName = (profile['fullName'] ?? '').toString();
    AuthSession.address = (profile['address'] ?? '').toString();
    AuthSession.phoneNumber = (profile['phoneNumber'] ?? '').toString();
    AuthSession.avatarUrl = (profile['avatarUrl'] ?? '').toString();
    if (AuthSession.avatarUrl != null && AuthSession.avatarUrl!.isEmpty) {
      AuthSession.avatarUrl = null;
    }
  }
}
