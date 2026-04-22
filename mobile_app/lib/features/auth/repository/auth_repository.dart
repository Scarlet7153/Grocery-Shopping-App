import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../../../core/enums/app_type.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Login user with credentials
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
    required AppType appType, // Bây giờ AppType đã được import
    bool rememberMe = false,
  });

  /// Register new user
  Future<AuthResponseModel> register({
    required Map<String, dynamic> userData,
    required AppType appType,
  });

  /// Update user profile
  Future<UserModel> updateProfile({
    required Map<String, dynamic> userData,
  });

  /// Change user password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Logout current user
  Future<void> logout();

  /// Refresh authentication token
  Future<AuthResponseModel> refreshToken({required String refreshToken});

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Get current user data
  Future<UserModel?> getCurrentUser();

  /// Get stored auth token
  Future<String?> getAuthToken();

  /// Clear stored authentication data
  Future<void> clearAuthData();

  /// Save authentication data to local storage
  Future<void> saveAuthData({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiry,
  });

  /// Forgot password request
  Future<AuthResponseModel> forgotPassword({
    required String identifier,
    required AppType appType, // Bây giờ AppType đã được import
  });

  /// Reset password with new password
  Future<AuthResponseModel> resetPassword({
    required String newPassword,
    required String confirmPassword,
    required String resetToken,
  });

  /// Update FCM token for push notifications
  Future<void> updateFcmToken({required String fcmToken});

  /// Get app-specific user permissions
  Future<List<String>> getUserPermissions({
    required AppType appType,
  }); // Bây giờ AppType đã được import
}
