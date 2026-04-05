enum AppType {
  customer,  // App riêng cho khách hàng
  store,     // App riêng cho chủ cửa hàng  
  shipper,   // App riêng cho shipper
  admin,     // Web app riêng cho admin
}

<<<<<<< HEAD
extension AppTypeExtension on AppType {
  // Trả về chuỗi để gửi lên API (backend)
  String get roleString {
    switch (this) {
      case AppType.customer:
        return 'CUSTOMER';
      case AppType.store:
        return 'STORE';
      case AppType.shipper:
        return 'SHIPPER';
      case AppType.admin:
        return 'ADMIN';
    }
  }

  // Trả về chuỗi để hiển thị trên giao diện (UI)
  String get displayName {
    switch (this) {
      case AppType.customer:
        return 'Khách hàng';
      case AppType.store:
        return 'Cửa hàng';
      case AppType.shipper:
        return 'Giao hàng';
      case AppType.admin:
        return 'Quản trị viên';
=======
extension AppTypeExt on AppType {
  String get displayName {
    switch (this) {
      case AppType.customer:
        return 'Customer';
      case AppType.store:
        return 'Store';
      case AppType.shipper:
        return 'Shipper';
      case AppType.admin:
        return 'Admin';
    }
  }

  /// String used by backend / permission mapping
  String get roleString {
    switch (this) {
      case AppType.customer:
        return 'customer';
      case AppType.store:
        return 'store_owner';
      case AppType.shipper:
        return 'shipper';
      case AppType.admin:
        return 'admin';
>>>>>>> mobile_app
    }
  }
}