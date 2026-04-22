import 'package:equatable/equatable.dart';
import '../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during authentication operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Successfully authenticated state
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  @override
  List<Object> get props => [user, token];

  @override
  String toString() =>
      'AuthAuthenticated { user: ${user.fullName}, role: ${user.role.name} }'; // Sửa từ user.name thành user.fullName

  /// Convenience getters
  String get userId => user.id;
  String get userName => user.fullName; // Thêm getter để dễ sử dụng
  String get userPhone => user.phoneNumber;
  UserRole get userRole => user.role;
  bool get isActive => user.isActive;
  bool get isStoreOwner => user.role == UserRole.store;
  bool get isCustomer => user.role == UserRole.customer;
  bool get isShipper => user.role == UserRole.shipper;
  bool get isAdmin => user.role == UserRole.admin;

  /// Check if user has specific permissions
  bool hasPermission(String permission) {
    // Implementation based on user role
    switch (user.role) {
      case UserRole.customer:
        return [
          'view_products',
          'create_order',
          'view_orders',
        ].contains(permission);
      case UserRole.store:
        return [
          'manage_inventory',
          'view_store_orders',
          'manage_products',
        ].contains(permission);
      case UserRole.shipper:
        return [
          'view_available_orders',
          'accept_delivery',
          'update_delivery_status',
        ].contains(permission);
      case UserRole.admin:
        return true; // Admin has all permissions
    }
  }
}

/// Authentication failed state
class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];

  @override
  String toString() => 'AuthError { message: $message, code: $errorCode }';

  /// Check if error is network related
  bool get isNetworkError => errorCode?.contains('network') ?? false;

  /// Check if error is validation related
  bool get isValidationError => errorCode?.contains('validation') ?? false;

  /// Check if error is server related
  bool get isServerError => errorCode?.contains('server') ?? false;
}

/// User logged out state
class AuthUnauthenticated extends AuthState {
  final String? reason;

  const AuthUnauthenticated({this.reason});

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'AuthUnauthenticated { reason: $reason }';
}

/// Token refresh in progress
class AuthTokenRefreshing extends AuthState {
  final UserModel user;

  const AuthTokenRefreshing({required this.user});

  @override
  List<Object> get props => [user];

  @override
  String toString() => 'AuthTokenRefreshing { user: ${user.fullName} }'; // Sửa từ user.name thành user.fullName
}

/// Registration states
class AuthRegistering extends AuthState {
  const AuthRegistering();
}

class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthRegistrationError extends AuthState {
  final String message;
  final Map<String, dynamic>? validationErrors;

  const AuthRegistrationError({required this.message, this.validationErrors});

  @override
  List<Object?> get props => [message, validationErrors];

  /// Get specific field error
  String? getFieldError(String fieldName) {
    return validationErrors?[fieldName]?.toString();
  }

  /// Check if has validation errors
  bool get hasValidationErrors =>
      validationErrors != null && validationErrors!.isNotEmpty;
}

/// Password reset states
class AuthPasswordResetLoading extends AuthState {
  const AuthPasswordResetLoading();
}

class AuthPasswordResetSent extends AuthState {
  final String message;

  const AuthPasswordResetSent({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthPasswordResetError extends AuthState {
  final String message;

  const AuthPasswordResetError({required this.message});

  @override
  List<Object> get props => [message];
}

/// Session expired state
class AuthSessionExpired extends AuthState {
  final String message;

  const AuthSessionExpired({
    this.message = 'Session expired. Please login again.',
  });

  @override
  List<Object> get props => [message];
}

/// Profile update states
class AuthProfileUpdating extends AuthState {
  const AuthProfileUpdating();
}

class AuthProfileUpdated extends AuthState {
  final UserModel updatedUser;

  const AuthProfileUpdated({required this.updatedUser});

  @override
  List<Object> get props => [updatedUser];

  @override
  String toString() => 'AuthProfileUpdated { user: ${updatedUser.fullName} }';
}

class AuthProfileUpdateError extends AuthState {
  final String message;

  const AuthProfileUpdateError({required this.message});

  @override
  List<Object> get props => [message];
}

/// Extension methods for AuthState
extension AuthStateExtensions on AuthState {
  /// Check if user is authenticated
  bool get isAuthenticated => this is AuthAuthenticated;

  /// Check if in loading state
  bool get isLoading =>
      this is AuthLoading ||
      this is AuthRegistering ||
      this is AuthTokenRefreshing ||
      this is AuthPasswordResetLoading ||
      this is AuthProfileUpdating;

  /// Check if has error
  bool get hasError =>
      this is AuthError ||
      this is AuthRegistrationError ||
      this is AuthPasswordResetError ||
      this is AuthProfileUpdateError;

  /// Get current user if authenticated
  UserModel? get currentUser {
    final state = this;
    if (state is AuthAuthenticated) {
      return state.user;
    } else if (state is AuthTokenRefreshing) {
      return state.user;
    } else if (state is AuthProfileUpdated) {
      return state.updatedUser;
    }
    return null;
  }

  /// Get current auth token if available
  String? get currentToken {
    final state = this;
    if (state is AuthAuthenticated) {
      return state.token;
    }
    return null;
  }

  /// Get error message if in error state
  String? get errorMessage {
    final state = this;
    if (state is AuthError) {
      return state.message;
    } else if (state is AuthRegistrationError) {
      return state.message;
    } else if (state is AuthPasswordResetError) {
      return state.message;
    } else if (state is AuthProfileUpdateError) {
      return state.message;
    }
    return null;
  }
}
