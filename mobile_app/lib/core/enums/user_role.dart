import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// User roles enum for the grocery shopping app
/// Each role has different permissions and UI flows
enum UserRole {
  /// Customer - End user who places orders
  customer('customer', 'Khách hàng', 'Đặt hàng và mua sắm'),

  /// Store Owner - Manages store, products, and orders
  store('store', 'Chủ cửa hàng', 'Quản lý cửa hàng và sản phẩm'),

  /// Shipper - Delivers orders to customers
  shipper('shipper', 'Shipper', 'Giao hàng cho khách hàng'),

  /// Admin - System administrator with full access
  admin('admin', 'Quản trị viên', 'Quản trị hệ thống');

  const UserRole(this.id, this.displayName, this.description);

  /// Unique identifier for the role
  final String id;

  /// Display name in Vietnamese
  final String displayName;

  /// Role description
  final String description;

  /// Get primary color for this role
  Color get primaryColor {
    switch (this) {
      case UserRole.customer:
        return AppColors.customerPrimary;
      case UserRole.store:
        return AppColors.storePrimary;
      case UserRole.shipper:
        return AppColors.shipperPrimary;
      case UserRole.admin:
        return AppColors.adminPrimary;
    }
  }

  /// Get light color for this role
  Color get lightColor {
    switch (this) {
      case UserRole.customer:
        return AppColors.customerPrimaryLight;
      case UserRole.store:
        return AppColors.storePrimaryLight;
      case UserRole.shipper:
        return AppColors.shipperPrimaryLight;
      case UserRole.admin:
        return AppColors.adminPrimaryLight;
    }
  }

  /// Get dark color for this role
  Color get darkColor {
    switch (this) {
      case UserRole.customer:
        return AppColors.customerPrimaryDark;
      case UserRole.store:
        return AppColors.storePrimaryDark;
      case UserRole.shipper:
        return AppColors.shipperPrimaryDark;
      case UserRole.admin:
        return AppColors.adminPrimaryDark;
    }
  }

  /// Get container color for this role
  Color get containerColor {
    switch (this) {
      case UserRole.customer:
        return AppColors.customerContainer;
      case UserRole.store:
        return AppColors.storeContainer;
      case UserRole.shipper:
        return AppColors.shipperContainer;
      case UserRole.admin:
        return AppColors.adminContainer;
    }
  }

  /// Get gradient for this role
  LinearGradient get gradient {
    switch (this) {
      case UserRole.customer:
        return AppColors.customerGradient;
      case UserRole.store:
        return AppColors.storeGradient;
      case UserRole.shipper:
        return AppColors.shipperGradient;
      case UserRole.admin:
        return AppColors.adminGradient;
    }
  }

  /// Get icon for this role
  IconData get icon {
    switch (this) {
      case UserRole.customer:
        return Icons.shopping_cart_outlined;
      case UserRole.store:
        return Icons.store_outlined;
      case UserRole.shipper:
        return Icons.delivery_dining_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  /// Get filled icon for this role
  IconData get iconFilled {
    switch (this) {
      case UserRole.customer:
        return Icons.shopping_cart;
      case UserRole.store:
        return Icons.store;
      case UserRole.shipper:
        return Icons.delivery_dining;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  /// Check if this role has administrative privileges
  bool get isAdmin => this == UserRole.admin;

  /// Check if this role can manage products
  bool get canManageProducts =>
      this == UserRole.store || this == UserRole.admin;

  /// Check if this role can process orders
  bool get canProcessOrders => this == UserRole.store || this == UserRole.admin;

  /// Check if this role can deliver orders
  bool get canDeliverOrders =>
      this == UserRole.shipper || this == UserRole.admin;

  /// Check if this role can place orders
  bool get canPlaceOrders => this == UserRole.customer;

  /// Get role from string ID
  static UserRole fromString(String roleId) {
    return UserRole.values.firstWhere(
      (role) => role.id == roleId.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }

  /// Get all roles except admin (for mobile app)
  static List<UserRole> get mobileRoles => [
        UserRole.customer,
        UserRole.store,
        UserRole.shipper,
      ];

  /// Get all roles including admin (for web app)
  static List<UserRole> get allRoles => UserRole.values;
}
