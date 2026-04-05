import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class AuthLoginRequest {
  final String phoneNumber;
  final String password;

  const AuthLoginRequest({
    required this.phoneNumber,
    required this.password,
  });

  factory AuthLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthLoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AuthLoginRequestToJson(this);
}

@JsonSerializable()
class AuthRegisterRequest {
  final String phoneNumber;
  final String password;
  final String? name;
  final String? email;
  final String? role;

  const AuthRegisterRequest({
    required this.phoneNumber,
    required this.password,
    this.name,
    this.email,
    this.role,
  });

  factory AuthRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AuthRegisterRequestToJson(this);
}

@JsonSerializable()
class AuthUser {
  final String? id;
  final String? phoneNumber;
  final String? name;
  final String? email;
  final String? role;

  const AuthUser({
    this.id,
    this.phoneNumber,
    this.name,
    this.email,
    this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String token;
  final String? refreshToken;
  final AuthUser? user;

  const AuthResponse({
    required this.token,
    this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
