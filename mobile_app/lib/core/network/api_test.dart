import '../utils/logger.dart'; // Import logger
import 'api_client.dart';
import 'api_endpoints.dart';

class ApiTester {
  final ApiClient _apiClient;

  ApiTester(this._apiClient);

  /// Test API connection
  Future<void> testConnection() async {
    try {
      // Test basic connection với health check endpoint
      final response = await _apiClient.get('/health');
      AppLogger.info('API Connection Test: ${response.statusCode}');
      AppLogger.debug('Health Check Response: ${response.data}');
    } catch (e) {
      AppLogger.error('API Connection Failed', e);
    }
  }

  /// Test authentication endpoints
  Future<void> testAuthEndpoints() async {
    try {
      // Test register endpoint với invalid data để kiểm tra response format
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'phoneNumber': '',
          'password': '',
          'fullName': '',
          'role': 'CUSTOMER',
        },
      );
      AppLogger.debug('Auth Test Response: ${response.data}');
    } catch (e) {
      AppLogger.warning('Auth Test Error (Expected): $e');
    }
  }

  /// Test với valid data
  Future<void> testValidAuth() async {
    try {
      AppLogger.info('Testing auth with sample data...');
      
      final loginData = {
        'phoneNumber': '0901234567',
        'password': '123456',
      };
      
      final response = await _apiClient.post(ApiEndpoints.login, data: loginData);
      AppLogger.info('Login test successful: ${response.statusCode}');
      
    } catch (e) {
      AppLogger.error('Login test failed', e);
    }
  }
}