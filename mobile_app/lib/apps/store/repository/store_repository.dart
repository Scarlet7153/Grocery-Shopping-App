import 'package:dio/dio.dart';

class StoreRepository {
  /// Bật/tắt mock API
  /// true = dùng dữ liệu giả
  /// false = gọi backend thật
  static const bool useMock = true;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:4000",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// LOGIN
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    /// MOCK API
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      if (phoneNumber == "0901234567" && password == "123456") {
        return {
          "token": "mock_token_123456",
          "user": {"phoneNumber": phoneNumber, "role": "STORE"},
        };
      } else {
        throw Exception("Sai số điện thoại hoặc mật khẩu");
      }
    }

    /// REAL API
    final response = await _dio.post(
      "/auth/login",
      data: {"phoneNumber": phoneNumber, "password": password},
    );

    return response.data;
  }

  /// DASHBOARD DATA
  Future<Map<String, dynamic>> getMyStore(String token) async {
    /// MOCK API
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      return {
        "name": "Siêu Thị Mini B",
        "address": "456 Đường Lê Lợi, Q3",
        "status": "OPEN",
        "revenueToday": 2500000,
        "ordersToday": 18,
      };
    }

    /// REAL API
    final response = await _dio.get(
      "/store/my-store",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return response.data;
  }
}
