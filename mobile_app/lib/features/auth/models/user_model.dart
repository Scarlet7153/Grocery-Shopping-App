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
  @JsonValue('BANNED')
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Xử lý id từ backend (đôi khi trả về int thay vì String)
    final idValue = json['id'] ?? json['userId'];
    final idStr = idValue?.toString() ?? '';
    
    return UserModel(
      id: idStr,
      phoneNumber: json['phoneNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      role: _parseRole(json['role']),
      status: _parseStatus(json['status']),
      address: json['address'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      storeName: json['storeName'],
      storeAddress: json['storeAddress'],
    );
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.customer;
    if (role is UserRole) return role;
    final roleStr = role.toString().toUpperCase();
    if (roleStr == 'ADMIN') return UserRole.admin;
    if (roleStr == 'STORE') return UserRole.store;
    if (roleStr == 'SHIPPER') return UserRole.shipper;
    return UserRole.customer;
  }

  static UserStatus _parseStatus(dynamic status) {
    if (status == null) return UserStatus.active;
    if (status is UserStatus) return status;
    final statusStr = status.toString().toUpperCase();
    if (statusStr == 'ACTIVE') return UserStatus.active;
    if (statusStr == 'BANNED' || statusStr == 'INACTIVE') return UserStatus.inactive;
    if (statusStr == 'SUSPENDED') return UserStatus.suspended;
    return UserStatus.active;
  }

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
  String toString() =>
      'UserModel { id: $id, fullName: $fullName, role: $role }';
}
