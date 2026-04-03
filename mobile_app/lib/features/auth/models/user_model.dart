import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Enum for user roles theo API backend
enum UserRole {
  @JsonValue('CUSTOMER')
  customer,
  @JsonValue('STORE') 
  store,
  @JsonValue('SHIPPER')
  shipper,
  @JsonValue('ADMIN')
  admin,
}

/// User status enum theo API
enum UserStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('INACTIVE')
  inactive,
  @JsonValue('SUSPENDED')
  suspended,
}

/// User model theo format API response
@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final UserStatus status;
  final String? address;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Store-specific fields
  final String? storeName;
  final String? storeAddress;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    required this.status,
    this.address,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.storeName,
    this.storeAddress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Create copy with updated fields
  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    UserRole? role,
    UserStatus? status,
    String? address,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storeName,
    String? storeAddress,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
    );
  }

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Get display name for role
  String get roleDisplayName {
    switch (role) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.store:
        return 'Chủ cửa hàng';
      case UserRole.shipper:
        return 'Tài xế giao hàng';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        fullName,
        role,
        status,
        address,
        avatarUrl,
        createdAt,
        updatedAt,
        storeName,
        storeAddress,
      ];

  @override
  String toString() => 'UserModel { id: $id, fullName: $fullName, role: $role }';
}