// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseModel _$AuthResponseModelFromJson(Map<String, dynamic> json) =>
    AuthResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : AuthDataModel.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseModelToJson(AuthResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AuthDataModel _$AuthDataModelFromJson(Map<String, dynamic> json) =>
    AuthDataModel(
      token: json['token'] as String?,
      type: json['type'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      phoneNumber: json['phoneNumber'] as String?,
      fullName: json['fullName'] as String?,
      role: json['role'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$AuthDataModelToJson(AuthDataModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'type': instance.type,
      'userId': instance.userId,
      'phoneNumber': instance.phoneNumber,
      'fullName': instance.fullName,
      'role': instance.role,
      'avatarUrl': instance.avatarUrl,
    };

LoginRequestModel _$LoginRequestModelFromJson(Map<String, dynamic> json) =>
    LoginRequestModel(
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestModelToJson(LoginRequestModel instance) =>
    <String, dynamic>{
      'phoneNumber': instance.phoneNumber,
      'password': instance.password,
    };

RegisterRequestModel _$RegisterRequestModelFromJson(
  Map<String, dynamic> json,
) => RegisterRequestModel(
  phoneNumber: json['phoneNumber'] as String,
  password: json['password'] as String,
  fullName: json['fullName'] as String,
  role: json['role'] as String,
  address: json['address'] as String?,
  storeName: json['storeName'] as String?,
  storeAddress: json['storeAddress'] as String?,
);

Map<String, dynamic> _$RegisterRequestModelToJson(
  RegisterRequestModel instance,
) => <String, dynamic>{
  'phoneNumber': instance.phoneNumber,
  'password': instance.password,
  'fullName': instance.fullName,
  'role': instance.role,
  'address': instance.address,
  'storeName': instance.storeName,
  'storeAddress': instance.storeAddress,
};
