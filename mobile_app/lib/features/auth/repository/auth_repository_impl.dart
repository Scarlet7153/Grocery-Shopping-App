import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  // Storage keys
  static const String _keyUser = 'auth_user';
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyUserId = 'auth_user_id';

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required SharedPreferences prefs,
  })  : _apiClient = apiClient,
        _prefs = prefs {
    AppLogger.debug('AuthRepositoryImpl initialized');
  }

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
    required AppType appType,
    bool rememberMe = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      AppLogger.info('🔐 Login attempt for ${appType.name} app with identifier: ${_maskIdentifier(identifier)}');
      
      final requestData = LoginRequestModel(
        phoneNumber: identifier,
        password: password,
      );

      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: requestData.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.isAuthenticated) {
        AppLogger.info('✅ Login successful - User: ${authResponse.user?.fullName}, Role: ${authResponse.user?.role.name}');
        
        await _saveAuthData(authResponse);
        
        // Lấy thông tin user chi tiết nếu cần
        if (authResponse.data?.token != null) {
          await _fetchAndSaveUserProfile(authResponse.data!.token!);
        }
      } else {
        AppLogger.warning('❌ Login failed: ${authResponse.message}');
      }

      final duration = stopwatch.elapsed;
      if (duration.inMilliseconds > 2000) {
        AppLogger.warning('⏱️ Login operation took ${duration.inMilliseconds}ms (slow)');
      } else {
        AppLogger.debug('⏱️ Login operation completed in ${duration.inMilliseconds}ms');
      }
      
      return authResponse;
      
    } on DioException catch (e) {
      AppLogger.error('🔥 Login DioException: ${e.message}', e);
      
      throw ServerException(
        message: 'Đăng nhập thất bại: ${e.response?.data?['message'] ?? e.message}',
        statusCode: e.response?.statusCode ?? 400,
      );
    } catch (e) {
      AppLogger.error('💥 Login unexpected error: ${e.toString()}', e);
      
      throw ServerException(
        message: 'Đã xảy ra lỗi không xác định: ${e.toString()}',
        statusCode: 400,
      );
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<AuthResponseModel> register({
    required Map<String, dynamic> userData,
    required AppType appType,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      AppLogger.info('🔐 Registration attempt for ${appType.name} app with phone: ${_maskIdentifier(userData['phoneNumber'])}');
      
      final requestData = RegisterRequestModel(
        phoneNumber: userData['phoneNumber'],
        password: userData['password'],
        fullName: userData['fullName'],
        role: _mapAppTypeToRole(appType),
        address: userData['address'],
        storeName: userData['storeName'],
        storeAddress: userData['storeAddress'],
      );

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: requestData.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.isAuthenticated) {
        AppLogger.info('✅ Registration successful - User: ${authResponse.user?.fullName}, Role: ${authResponse.user?.role.name}');
        
        await _saveAuthData(authResponse);
      } else {
        AppLogger.warning('❌ Registration failed: ${authResponse.message}');
      }

      final duration = stopwatch.elapsed;
      AppLogger.debug('⏱️ Registration operation completed in ${duration.inMilliseconds}ms');
      
      return authResponse;
      
    } on DioException catch (e) {
      AppLogger.error('🔥 Registration DioException: ${e.message}', e);
      
      throw ServerException(
        message: 'Đăng ký thất bại: ${e.response?.data?['message'] ?? e.message}',
        statusCode: e.response?.statusCode ?? 400,
      );
    } catch (e) {
      AppLogger.error('💥 Registration unexpected error: ${e.toString()}', e);
      
      throw ServerException(
        message: 'Đã xảy ra lỗi không xác định: ${e.toString()}',
        statusCode: 400,
      );
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<void> logout() async {
    try {
      AppLogger.info('🔐 Logout attempt');
      
      // API logout không cần body theo Postman
      await _apiClient.post(ApiEndpoints.logout);
      
      AppLogger.info('✅ Logout API call successful');
    } catch (e) {
      AppLogger.warning('⚠️ Logout API call failed, but continuing with local cleanup: ${e.toString()}');
    } finally {
      await clearAuthData();
      AppLogger.info('🧹 User logged out and auth data cleared');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    try {
      AppLogger.info('🎫 Refreshing access token');
      
      final token = await getAuthToken();
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.isAuthenticated) {
        AppLogger.info('✅ Token refresh successful');
        await _saveAuthData(authResponse);
      } else {
        AppLogger.warning('❌ Token refresh failed: Invalid token response');
      }

      return authResponse;
      
    } on DioException catch (e) {
      AppLogger.error('🔥 Token refresh failed: ${e.message}', e);
      
      // Clear auth data on refresh failure
      await clearAuthData();
      AppLogger.warning('🧹 Auth data cleared due to token refresh failure');
      
      throw ServerException(
        message: 'Làm mới token thất bại: ${e.response?.data?['message'] ?? e.message}',
        statusCode: e.response?.statusCode ?? 401,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAuthToken();
      final user = await getCurrentUser();
      final authenticated = token != null && user != null;
      
      AppLogger.debug('🔍 Authentication check: ${authenticated ? 'authenticated' : 'not authenticated'}');
      return authenticated;
      
    } catch (e) {
      AppLogger.error('💥 Authentication check error: ${e.toString()}', e);
      return false;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = _prefs.getString(_keyUser);
      if (userJson == null) {
        AppLogger.debug('📝 No user data in storage');
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserModel.fromJson(userMap);
      
      AppLogger.debug('👤 Retrieved user: ${user.fullName} (${user.role.name})');
      return user;
      
    } catch (e) {
      AppLogger.error('💥 Error retrieving user data: ${e.toString()}', e);
      return null;
    }
  }

  @override
  Future<String?> getAuthToken() async {
    try {
      final token = _prefs.getString(_keyAccessToken);
      if (token != null) {
        AppLogger.debug('🎫 Auth token retrieved from storage');
      } else {
        AppLogger.debug('🚫 No auth token in storage');
      }
      return token;
    } catch (e) {
      AppLogger.error('💥 Error retrieving auth token: ${e.toString()}', e);
      return null;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _prefs.remove(_keyUser),
        _prefs.remove(_keyAccessToken),
        _prefs.remove(_keyUserId),
      ]);
      
      AppLogger.info('🧹 Auth data cleared from storage');
    } catch (e) {
      AppLogger.error('💥 Error clearing auth data: ${e.toString()}', e);
    }
  }

  /// Save authentication data từ response
  Future<void> _saveAuthData(AuthResponseModel authResponse) async {
    try {
      final futures = <Future>[];
      
      if (authResponse.data?.token != null) {
        futures.add(_prefs.setString(_keyAccessToken, authResponse.data!.token!));
        AppLogger.debug('🎫 Access token saved to storage');
      }
      
      if (authResponse.data?.userId != null) {
        futures.add(_prefs.setString(_keyUserId, authResponse.data!.userId!));
      }

      if (authResponse.user != null) {
        futures.add(_prefs.setString(_keyUser, jsonEncode(authResponse.user!.toJson())));
      }
      
      await Future.wait(futures);
      AppLogger.info('💾 Auth data saved to storage');
      
    } catch (e) {
      AppLogger.error('💥 Error saving auth data: ${e.toString()}', e);
    }
  }

  /// Fetch user profile from /auth/me endpoint
  Future<void> _fetchAndSaveUserProfile(String token) async {
    try {
      AppLogger.debug('🔄 Fetching user profile from API');
      
      final response = await _apiClient.get(
        ApiEndpoints.getProfile,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final user = UserModel.fromJson(response.data['data']);
        await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
        
        AppLogger.info('✅ User profile updated: ${user.fullName} (${user.role.name})');
      } else {
        AppLogger.warning('⚠️ Failed to fetch user profile: Invalid response format');
      }
    } catch (e) {
      AppLogger.warning('⚠️ Failed to fetch user profile: ${e.toString()}');
      // Ignore profile fetch errors - not critical for authentication flow
    }
  }

  /// Map AppType to API role string
  String _mapAppTypeToRole(AppType appType) {
    final role = appType.roleString;
    AppLogger.debug('🔄 Mapping ${appType.name} to role: $role');
    return role;
  }

  /// Mask sensitive identifier for logging
  String _maskIdentifier(String identifier) {
    if (identifier.length <= 4) return '****';
    return '${identifier.substring(0, 2)}****${identifier.substring(identifier.length - 2)}';
  }

  // Implement other required methods...
  @override
  Future<void> saveAuthData({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiry,
  }) async {
    try {
      AppLogger.info('💾 Saving auth data for user: ${user.fullName}');
      
      await Future.wait([
        _prefs.setString(_keyUser, jsonEncode(user.toJson())),
        _prefs.setString(_keyAccessToken, accessToken),
      ]);
      
      AppLogger.info('✅ Auth data saved successfully');
    } catch (e) {
      AppLogger.error('💥 Error in saveAuthData: ${e.toString()}', e);
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> forgotPassword({
    required String identifier,
    required AppType appType,
  }) async {
    AppLogger.warning('⚠️ Forgot password requested but not implemented in API');
    throw UnimplementedError('Forgot password chưa được implement trong API');
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String otp,
    required String identifier,
    String? resetToken,
  }) async {
    AppLogger.warning('⚠️ OTP verification requested but not implemented in API');
    throw UnimplementedError('OTP verification chưa được implement trong API');
  }

  @override
  Future<AuthResponseModel> resetPassword({
    required String newPassword,
    required String confirmPassword,
    required String resetToken,
  }) async {
    AppLogger.warning('⚠️ Password reset requested but not implemented in API');
    throw UnimplementedError('Password reset chưa được implement trong API');
  }

  @override
  Future<void> updateFcmToken({required String fcmToken}) async {
    AppLogger.info('🔔 FCM token update requested: ${_maskIdentifier(fcmToken)}');
    AppLogger.info('🚧 FCM token update not yet implemented - awaiting API endpoint');
  }

  @override
  Future<List<String>> getUserPermissions({required AppType appType}) async {
    AppLogger.debug('🔑 Getting permissions for app type: ${appType.name}');
    
    AppLogger.debug('🚧 Using default role-based permissions - implement API-based permissions later');
    final permissions = <String>[];
    
    switch (appType) {
      case AppType.customer:
        permissions.addAll([
          'view_products',
          'create_order', 
          'view_orders',
          'write_reviews',
          'update_profile'
        ]);
        break;
      case AppType.store:
        permissions.addAll([
          'manage_inventory',
          'view_store_orders',
          'update_store',
          'manage_products',
          'view_analytics'
        ]);
        break;
      case AppType.shipper:
        permissions.addAll([
          'view_available_orders',
          'accept_delivery',
          'update_delivery_status',
          'view_delivery_history',
          'update_location'
        ]);
        break;
      case AppType.admin:
        permissions.addAll([
          'manage_users',
          'manage_stores', 
          'view_analytics',
          'manage_categories',
          'system_settings'
        ]);
        break;
    }
    
    AppLogger.debug('🔑 Permissions for ${appType.name}: ${permissions.join(', ')}');
    return permissions;
  }
}