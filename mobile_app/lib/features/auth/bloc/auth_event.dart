import 'package:equatable/equatable.dart';
import '../../../core/config/app_config.dart';
import '../../../core/enums/app_type.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Login event
class LoginRequested extends AuthEvent {
  final String identifier;
  final String password;
  final AppType appType;
  final bool rememberMe;

  const LoginRequested({
    required this.identifier,
    required this.password,
    required this.appType,
    this.rememberMe = false,
  });

  @override
  List<Object> get props => [identifier, password, appType, rememberMe];

  @override
  String toString() =>
      'LoginRequested { identifier: $identifier, appType: $appType }';
}

/// Register event
class RegisterRequested extends AuthEvent {
  final Map<String, dynamic> userData;
  final AppType appType;

  const RegisterRequested({required this.userData, required this.appType});

  @override
  List<Object> get props => [userData, appType];

  @override
  String toString() => 'RegisterRequested { appType: $appType }';
}

/// Logout event
class LogoutRequested extends AuthEvent {
  final String? reason;

  const LogoutRequested({this.reason});

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'LogoutRequested { reason: $reason }';
}

/// Token refresh event
class TokenRefreshRequested extends AuthEvent {
  final String? refreshToken;

  const TokenRefreshRequested({this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];

  @override
  String toString() => 'TokenRefreshRequested';
}

/// Check authentication status event
class CheckStatusRequested extends AuthEvent {
  const CheckStatusRequested();

  @override
  String toString() => 'CheckStatusRequested';
}

/// Forgot password event
class ForgotPasswordRequested extends AuthEvent {
  final String identifier;

  const ForgotPasswordRequested({required this.identifier});

  @override
  List<Object> get props => [identifier];

  @override
  String toString() => 'ForgotPasswordRequested { identifier: $identifier }';
}

/// OTP verification event
class OtpVerificationRequested extends AuthEvent {
  final String otp;
  final String identifier;
  final String? resetToken;

  const OtpVerificationRequested({
    required this.otp,
    required this.identifier,
    this.resetToken,
  });

  @override
  List<Object?> get props => [otp, identifier, resetToken];

  @override
  String toString() => 'OtpVerificationRequested { identifier: $identifier }';
}

/// Password reset event
class PasswordResetRequested extends AuthEvent {
  final String newPassword;
  final String confirmPassword;
  final String resetToken;

  const PasswordResetRequested({
    required this.newPassword,
    required this.confirmPassword,
    required this.resetToken,
  });

  @override
  List<Object> get props => [newPassword, confirmPassword, resetToken];

  @override
  String toString() => 'PasswordResetRequested';
}

/// Profile update event
class ProfileUpdateRequested extends AuthEvent {
  final Map<String, dynamic> userData;

  const ProfileUpdateRequested({required this.userData});

  @override
  List<Object> get props => [userData];

  @override
  String toString() => 'ProfileUpdateRequested { userData: $userData }';
}

/// FCM token update event
class FcmTokenUpdateRequested extends AuthEvent {
  final String fcmToken;

  const FcmTokenUpdateRequested({required this.fcmToken});

  @override
  List<Object> get props => [fcmToken];

  @override
  String toString() => 'FcmTokenUpdateRequested';
}

/// Session expired event (internal)
class SessionExpiredDetected extends AuthEvent {
  final String reason;

  const SessionExpiredDetected({this.reason = 'Session expired'});

  @override
  List<Object> get props => [reason];

  @override
  String toString() => 'SessionExpiredDetected { reason: $reason }';
}
