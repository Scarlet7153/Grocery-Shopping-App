import '../enums/app_type.dart';

class AppConfig {
  // Thay đổi cái này để build app khác nhau
<<<<<<< HEAD
  //static const AppType currentApp = AppType.customer; // <-- Change this
=======
  static const AppType currentApp = AppType.customer; // <-- Change this
>>>>>>> mobile_app

  //static const AppType currentApp = AppType.store;

  //static const AppType currentApp = AppType.shipper;

<<<<<<< HEAD
  static const String app =
    String.fromEnvironment('APP', defaultValue: 'admin');

static AppType get currentApp {
  switch (app) {
    case 'customer':
      return AppType.customer;
    case 'store':
      return AppType.store;
    case 'shipper':
      return AppType.shipper;
    case 'admin':
    default:
      return AppType.admin;
  }
}

  static String get appName {
    switch (currentApp) {
      case AppType.customer:
        return 'Đi Chợ Hộ - Khách Hàng';
      case AppType.store:
        return 'Đi Chợ Hộ - Chủ Cửa Hàng';
      case AppType.shipper:
        return 'Đi Chợ Hộ - Shipper';
      case AppType.admin:
        return 'Đi Chợ Hộ - Quản Trị Viên';
    }
  }
  
  static String get appId {
    switch (currentApp) {
      case AppType.customer:
        return 'com.dichohho.customer';
      case AppType.store:
        return 'com.dichohho.store';
      case AppType.shipper:
        return 'com.dichohho.shipper';
      case AppType.admin:
=======
  // static const AppType currentApp = AppType.admin;

  static String get appName {
    switch (currentApp) {
      case AppType.customer:
        return 'Đi Chợ Hộ - Khách Hàng';
      case AppType.store:
        return 'Đi Chợ Hộ - Chủ Cửa Hàng';
      case AppType.shipper:
        return 'Đi Chợ Hộ - Shipper';
      case AppType.admin:
        return 'Đi Chợ Hộ - Quản Trị Viên';
    }
  }
  
  static String get appId {
    switch (currentApp) {
      case AppType.customer:
        return 'com.dichohho.customer';
      case AppType.store:
        return 'com.dichohho.store';
      case AppType.shipper:
        return 'com.dichohho.shipper';
      case AppType.admin:
>>>>>>> mobile_app
        return 'com.dichohho.admin';
    }
  }
}