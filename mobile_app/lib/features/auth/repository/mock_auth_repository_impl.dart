import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';
import '../../../core/enums/app_type.dart';

class MockAuthRepositoryImpl implements AuthRepository {
  final SharedPreferences _prefs;

  static const String _keyUser = 'auth_user';
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyUserId = 'auth_user_id';

  MockAuthRepositoryImpl({
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    AppLogger.debug('MockAuthRepositoryImpl initialized 🛠️ (MOCK MODE)');
  }

  // --- DỮ LIỆU MOCK ---
  UserModel _createMockUser(AppType appType, String phone) {
    UserRole role;
    String name;

    switch (appType) {
      case AppType.admin:
        role = UserRole.admin;
        name = 'Super Admin';
        break;
      case AppType.store:
        role = UserRole.store;
        name = 'Cửa hàng Bách Hóa Nhiên';
        break;
      case AppType.shipper:
        role = UserRole.shipper;
        name = 'Tài xế giao hàng';
        break;
      case AppType.customer:
      default:
        role = UserRole.customer;
        name = 'Khách hàng Test';
    }

    return UserModel(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phone,
      fullName: name,
      role: role,
      status: UserStatus.active,
      address: '123 Đường Test, TP.HCM',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      storeName: role == UserRole.store ? 'Bách Hóa Nhiên' : null,
      storeAddress: role == UserRole.store ? '123 Đường Test, TP.HCM' : null,
    );
  }

 
  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
    required AppType appType,
    bool rememberMe = false,
  }) async {
    AppLogger.info('🛠️ [MOCK] Login attempt for ${appType.name} app with: $identifier');
    
    // Giả lập độ trễ mạng 1.5 giây để nhìn thấy vòng xoay loading
    await Future.delayed(const Duration(milliseconds: 1500));

    // Kiểm tra đúng số điện thoại và mật khẩu bạn yêu cầu
    if (identifier == '0987654321' && password == '123456') {
      AppLogger.info('✅ [MOCK] Đăng nhập thành công với SĐT: $identifier');
      
      final mockUser = _createMockUser(appType, identifier);
      final mockToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

      final authData = AuthDataModel(
        token: mockToken,
        userId: mockUser.id,
        user: mockUser,
      );

      final response = AuthResponseModel(
        success: true,
        message: 'Đăng nhập giả lập thành công',
        data: authData,
      );

      // Lưu data vào bộ nhớ thiết bị
      await saveAuthData(
        user: mockUser,
        accessToken: mockToken,
        refreshToken: 'mock_refresh_token',
        tokenExpiry: DateTime.now().add(const Duration(days: 7)),
      );

      return response;
    } else {
      // Nhập sai sẽ bắn ra lỗi để Bloc bắt được và hiển thị SnackBar đỏ
      AppLogger.warning('❌ [MOCK] Sai thông tin đăng nhập');
      throw Exception('Số điện thoại hoặc mật khẩu không chính xác!');
    }
  }

  @override
  Future<void> saveAuthData({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiry,
  }) async {
    AppLogger.info('🛠️ [MOCK] Saving auth data');
    await Future.wait([
      _prefs.setString(_keyUser, jsonEncode(user.toJson())),
      _prefs.setString(_keyAccessToken, accessToken),
      _prefs.setString(_keyUserId, user.id),
    ]);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    final user = await getCurrentUser();
    final authenticated = token != null && user != null;
    
    AppLogger.debug('🛠️ [MOCK] Auth check: ${authenticated ? "YES" : "NO"}');
    return authenticated;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userJson = _prefs.getString(_keyUser);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  @override
  Future<String?> getAuthToken() async {
    return _prefs.getString(_keyAccessToken);
  }

  @override
  Future<void> logout() async {
    AppLogger.info('🛠️ [MOCK] Logout');
    await clearAuthData();
  }

  @override
  Future<void> clearAuthData() async {
    await Future.wait([
      _prefs.remove(_keyUser),
      _prefs.remove(_keyAccessToken),
      _prefs.remove(_keyUserId),
    ]);
  }

  // --- CÁC HÀM KHÁC (Chỉ mock đơn giản trả về lỗi hoặc kết quả rỗng) ---
  @override
  Future<AuthResponseModel> register({required Map<String, dynamic> userData, required AppType appType}) async {
    throw UnimplementedError('Mock Register chưa được cài đặt');
  }

  @override
  Future<AuthResponseModel> refreshToken({required String refreshToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> forgotPassword({required String identifier, required AppType appType}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> verifyOtp({required String otp, required String identifier, String? resetToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> resetPassword({required String newPassword, required String confirmPassword, required String resetToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateFcmToken({required String fcmToken}) async {}

  @override
  Future<List<String>> getUserPermissions({required AppType appType}) async {
    return ['all_mock_permissions'];
  }
}