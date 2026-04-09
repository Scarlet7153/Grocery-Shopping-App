/// User Profile Model - represents shipper's profile data from backend
class UserProfile {
  final int id;
  final String phoneNumber;
  final String fullName;
  final String? avatarUrl;
  final String? address;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.avatarUrl,
    this.address,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from JSON response from backend
  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      address: json['address'] as String?,
      role: json['role'] as String? ?? 'SHIPPER',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'address': address,
      'role': role,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modifications
  UserProfile copyWith({
    int? id,
    String? phoneNumber,
    String? fullName,
    String? avatarUrl,
    String? address,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, phoneNumber: $phoneNumber, fullName: $fullName, '
      'role: $role, status: $status)';
}
