enum AppType {
  customer, // App riêng cho khách hàng
  store, // App riêng cho chủ cửa hàng
  shipper, // App riêng cho shipper
  admin, // Web app riêng cho admin
}

extension AppTypeExtension on AppType {
  // Trả về chuỗi để gửi lên API (backend)
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
    }
  }
}
