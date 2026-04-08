// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthLoginRequest _$AuthLoginRequestFromJson(Map<String, dynamic> json) =>
    AuthLoginRequest(
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$AuthLoginRequestToJson(AuthLoginRequest instance) =>
    <String, dynamic>{
      'phoneNumber': instance.phoneNumber,
      'password': instance.password,
    };

AuthRegisterRequest _$AuthRegisterRequestFromJson(Map<String, dynamic> json) =>
    AuthRegisterRequest(
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );

Map<String, dynamic> _$AuthRegisterRequestToJson(
  AuthRegisterRequest instance,
) => <String, dynamic>{
  'phoneNumber': instance.phoneNumber,
  'password': instance.password,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
};

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => AuthUser(
  id: json['id'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  name: json['name'] as String?,
  email: json['email'] as String?,
  role: json['role'] as String?,
);

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'phoneNumber': instance.phoneNumber,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  token: json['token'] as String,
  refreshToken: json['refreshToken'] as String?,
  user: json['user'] == null
      ? null
      : AuthUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };
