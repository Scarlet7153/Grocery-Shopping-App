import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../core/enums/app_type.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  Timer? _tokenRefreshTimer;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    // Register event handlers
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
    on<CheckStatusRequested>(_onCheckStatusRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<OtpVerificationRequested>(_onOtpVerificationRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);

    // Check authentication status on bloc initialization
    add(const CheckStatusRequested());
  }

  @override
  Future<void> close() {
    _tokenRefreshTimer?.cancel();
    return super.close();
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      AppLogger.info('🔐 Login attempt started');

      final authResponse = await _authRepository.login(
        identifier: event.identifier,
        password: event.password,
        appType: event.appType,
        rememberMe: event.rememberMe,
      );

      if (authResponse.isAuthenticated) {
        final user = authResponse.user!;
        final token = authResponse.data?.token ?? '';

        AppLogger.info('✅ Login successful for ${user.fullName}');

        // Enforce Admin role for Admin App
        if (event.appType == AppType.admin && user.role != UserRole.admin) {
          AppLogger.warning('🚫 Non-admin user ${user.fullName} attempted to login to Admin App');
          emit(const AuthError(
            message: 'Bạn không có quyền truy cập vào ứng dụng Admin. Vui lòng sử dụng tài khoản Admin.',
            errorCode: 'insufficient_permissions',
          ));
          return;
        }

        emit(AuthAuthenticated(user: user, token: token));

        // Start token refresh timer if needed
        _startTokenRefreshTimer();
      } else {
        AppLogger.warning('❌ Login failed: ${authResponse.message}');
        emit(
          AuthError(message: authResponse.message, errorCode: 'login_failed'),
        );
      }
    } on ServerException catch (e) {
      AppLogger.error('🔥 Login server error: ${e.message}', e);
      emit(AuthError(message: e.message, errorCode: 'server_error'));
    } catch (e) {
      AppLogger.error('💥 Login unexpected error: ${e.toString()}', e);
      emit(
        const AuthError(
          message: 'Đã xảy ra lỗi không xác định',
          errorCode: 'unknown_error',
        ),
      );
    }
  }

  /// Handle register request
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthRegistering());
      AppLogger.info('📝 Registration attempt started');

      final authResponse = await _authRepository.register(
        userData: event.userData,
        appType: event.appType,
      );

      if (authResponse.isAuthenticated) {
        AppLogger.info('✅ Registration successful');
        emit(
          const AuthRegistrationSuccess(
            message: 'Đăng ký thành công! Vui lòng đăng nhập.',
          ),
        );
      } else {
        AppLogger.warning('❌ Registration failed: ${authResponse.message}');
        emit(AuthRegistrationError(message: authResponse.message));
      }
    } on ServerException catch (e) {
      AppLogger.error('🔥 Registration server error: ${e.message}', e);
      emit(
        AuthRegistrationError(
          message: e.message,
          validationErrors: e.statusCode == 400 ? {'general': e.message} : null,
        ),
      );
    } catch (e) {
      AppLogger.error('💥 Registration unexpected error: ${e.toString()}', e);
      emit(
        const AuthRegistrationError(message: 'Đã xảy ra lỗi không xác định'),
      );
    }
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      AppLogger.info('🚪 Logout attempt started');

      // Cancel token refresh timer
      _tokenRefreshTimer?.cancel();

      // Call API logout
      await _authRepository.logout();

      AppLogger.info('✅ Logout successful');
      emit(AuthUnauthenticated(reason: event.reason ?? 'User logged out'));
    } catch (e) {
      AppLogger.warning('⚠️ Logout error (continuing): ${e.toString()}');
      // Still emit unauthenticated even if API call fails
      emit(AuthUnauthenticated(reason: event.reason ?? 'Logout with error'));
    }
  }

  /// Handle token refresh request
  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      emit(AuthTokenRefreshing(user: currentState.user));
      AppLogger.info('🔄 Token refresh attempt');

      final authResponse = await _authRepository.refreshToken(
        refreshToken: event.refreshToken ?? currentState.token,
      );

      if (authResponse.isAuthenticated) {
        final user = authResponse.user ?? currentState.user;
        final token = authResponse.data?.token ?? currentState.token;

        AppLogger.info('✅ Token refresh successful');
        emit(AuthAuthenticated(user: user, token: token));

        // Restart timer
        _startTokenRefreshTimer();
      } else {
        AppLogger.warning('❌ Token refresh failed: ${authResponse.message}');
        emit(const AuthSessionExpired());
      }
    } catch (e) {
      AppLogger.error('🔥 Token refresh error: ${e.toString()}', e);
      emit(const AuthSessionExpired());
    }
  }

  /// Handle check status request
  Future<void> _onCheckStatusRequested(
    CheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      AppLogger.debug('🔍 Checking authentication status');

      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.getAuthToken();

        if (user != null && token != null) {
          AppLogger.info('✅ User is authenticated: ${user.fullName}');
          emit(AuthAuthenticated(user: user, token: token));
          _startTokenRefreshTimer();
        } else {
          AppLogger.warning('⚠️ Invalid auth data, clearing');
          await _authRepository.clearAuthData();
          emit(const AuthUnauthenticated());
        }
      } else {
        AppLogger.debug('🚫 User not authenticated');
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      AppLogger.error('💥 Status check error: ${e.toString()}', e);
      emit(const AuthUnauthenticated(reason: 'Status check failed'));
    }
  }

  /// Handle forgot password request
  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthPasswordResetLoading());
      AppLogger.info('🔑 Forgot password attempt');

      final response = await _authRepository.forgotPassword(
        identifier: event.identifier,
        appType: AppType
            .customer, // Default to customer, sửa từ AppConfig.currentAppType
      );

      AppLogger.info('✅ Password reset sent');
      emit(AuthPasswordResetSent(message: response.message));
    } on UnimplementedError catch (e) {
      AppLogger.warning('⚠️ Forgot password not implemented: ${e.message}');
      emit(
        const AuthPasswordResetError(
          message: 'Tính năng quên mật khẩu chưa được hỗ trợ',
        ),
      );
    } catch (e) {
      AppLogger.error('🔥 Forgot password error: ${e.toString()}', e);
      emit(
        AuthPasswordResetError(
          message: 'Không thể gửi mã xác nhận: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle OTP verification request
  Future<void> _onOtpVerificationRequested(
    OtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthOtpVerifying());
      AppLogger.info('🔢 OTP verification attempt');

      final response = await _authRepository.verifyOtp(
        otp: event.otp,
        identifier: event.identifier,
        resetToken: event.resetToken,
      );

      if (response.isAuthenticated) {
        AppLogger.info('✅ OTP verified successfully');
        emit(AuthOtpVerified(message: response.message));
      } else {
        AppLogger.warning('❌ OTP verification failed');
        emit(AuthOtpError(message: response.message));
      }
    } on UnimplementedError catch (e) {
      AppLogger.warning('⚠️ OTP verification not implemented: ${e.message}');
      emit(
        const AuthOtpError(message: 'Tính năng xác nhận OTP chưa được hỗ trợ'),
      );
    } catch (e) {
      AppLogger.error('🔥 OTP verification error: ${e.toString()}', e);
      emit(AuthOtpError(message: 'Không thể xác nhận OTP: ${e.toString()}'));
    }
  }

  /// Handle password reset request
  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthPasswordResetLoading());
      AppLogger.info('🔄 Password reset attempt');

      final response = await _authRepository.resetPassword(
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
        resetToken: event.resetToken,
      );

      if (response.isAuthenticated) {
        AppLogger.info('✅ Password reset successful');
        emit(
          const AuthPasswordResetSent(message: 'Đặt lại mật khẩu thành công'),
        );
      } else {
        AppLogger.warning('❌ Password reset failed');
        emit(AuthPasswordResetError(message: response.message));
      }
    } on UnimplementedError catch (e) {
      AppLogger.warning('⚠️ Password reset not implemented: ${e.message}');
      emit(
        const AuthPasswordResetError(
          message: 'Tính năng đặt lại mật khẩu chưa được hỗ trợ',
        ),
      );
    } catch (e) {
      AppLogger.error('🔥 Password reset error: ${e.toString()}', e);
      emit(
        AuthPasswordResetError(
          message: 'Không thể đặt lại mật khẩu: ${e.toString()}',
        ),
      );
    }
  }

  /// Handle profile update request
  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      emit(const AuthProfileUpdating());
      AppLogger.info('👤 Profile update attempt');

      final updatedUser = await _authRepository.updateProfile(
        userData: event.userData,
      );

      AppLogger.info('✅ Profile updated successfully');
      emit(AuthProfileUpdated(updatedUser: updatedUser));

      // Return to authenticated state with updated user
      emit(AuthAuthenticated(
        user: updatedUser,
        token: currentState.token,
      ));
    } catch (e) {
      AppLogger.error('🔥 Profile update error: ${e.toString()}', e);
      emit(AuthProfileUpdateError(
        message: e is ServerException ? e.message : 'Không thể cập nhật thông tin',
      ));

      // Return to previous authenticated state
      emit(currentState);
    }
  }

  /// Handle change password request
  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      emit(const AuthPasswordResetLoading()); // Reusing loading state
      AppLogger.info('🔐 Change password attempt');

      await _authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      AppLogger.info('✅ Password changed successfully');
      emit(const AuthPasswordResetSent(
        message: 'Đổi mật khẩu thành công',
      ));
      
      // Return to authenticated state
      emit(currentState);
      
    } catch (e) {
      AppLogger.error('🔥 Change password error: ${e.toString()}', e);
      emit(AuthPasswordResetError(
        message: e is ServerException ? e.message : 'Không thể đổi mật khẩu',
      ));

      // Return to previous authenticated state
      emit(currentState);
    }
  }

  /// Start token refresh timer (15 minutes before expiry)
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();

    // Refresh token every 45 minutes (assuming 60 min expiry)
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (timer) {
      AppLogger.debug('🕐 Auto token refresh triggered');
      add(const TokenRefreshRequested());
    });

    AppLogger.debug('🕐 Token refresh timer started');
  }

  /// Helper method to check if user has permission
  bool hasPermission(String permission) {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.hasPermission(permission);
    }
    return false;
  }

  /// Helper method to get current user
  UserModel? get currentUser {
    return state.currentUser;
  }

  /// Helper method to get current token
  String? get currentToken {
    return state.currentToken;
  }

  /// Helper method to check authentication status
  bool get isAuthenticated {
    return state.isAuthenticated;
  }
}
