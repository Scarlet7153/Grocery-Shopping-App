import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

/// Authentication response model theo format API thực tế
@JsonSerializable()
class AuthResponseModel extends Equatable {
  final bool success;
  final String message;
  final AuthDataModel? data; // Nested data object

  const AuthResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  /// Check if response contains valid authentication data
  bool get isAuthenticated => success && data != null && data!.token != null;

  /// Get user from nested data
  UserModel? get user => data?.user;

  /// Get token from nested data
  String? get accessToken => data?.token;

  /// Get user ID
  String? get userId => data?.userId;

  @override
  List<Object?> get props => [success, message, data];
}

/// Nested data model for auth response
@JsonSerializable()
class AuthDataModel extends Equatable {
  final String? token;
  final String? userId;
  final UserModel? user; // Optional user data

  const AuthDataModel({
    this.token,
    this.userId,
    this.user,
  });

  factory AuthDataModel.fromJson(Map<String, dynamic> json) =>
      _$AuthDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthDataModelToJson(this);

  @override
  List<Object?> get props => [token, userId, user];
}

/// Login request model theo format API
@JsonSerializable()
class LoginRequestModel extends Equatable {
  final String phoneNumber; // API dùng phoneNumber thay vì identifier
  final String password;

  const LoginRequestModel({
    required this.phoneNumber,
    required this.password,
  });

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);

  @override
  List<Object?> get props => [phoneNumber, password];
}

/// Register request model theo format API
@JsonSerializable()
class RegisterRequestModel extends Equatable {
  final String phoneNumber;
  final String password;
  final String fullName;
  final String role; // CUSTOMER, STORE, SHIPPER, ADMIN
  final String? address; // For customer
  final String? storeName; // For store
  final String? storeAddress; // For store

  const RegisterRequestModel({
    required this.phoneNumber,
    required this.password,
    required this.fullName,
    required this.role,
    this.address,
    this.storeName,
    this.storeAddress,
  });

  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestModelToJson(this);

  @override
  List<Object?> get props => [
        phoneNumber,
        password,
        fullName,
        role,
        address,
        storeName,
        storeAddress,
      ];
}