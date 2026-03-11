enum AppType {
  customer,
  store,
  shipper,
  admin,
}

class AppConfig {
  // Current app type - có thể thay đổi dựa trên build variant hoặc runtime
  static AppType currentApp = AppType.customer;

  // App-specific configurations
  static const Map<AppType, AppConfiguration> _configs = {
    AppType.customer: AppConfiguration(
      appName: 'Customer App',
      primaryColor: 0xFF2E7D32, // Green
      appId: 'com.grocery.customer',
      features: ['shopping', 'orders', 'reviews'],
    ),
    AppType.store: AppConfiguration(
      appName: 'Store Management',
      primaryColor: 0xFF1565C0, // Blue
      appId: 'com.grocery.store',
      features: ['inventory', 'orders', 'analytics'],
    ),
    AppType.shipper: AppConfiguration(
      appName: 'Shipper App',
      primaryColor: 0xFFFF6F00, // Orange
      appId: 'com.grocery.shipper',
      features: ['delivery', 'tracking', 'earnings'],
    ),
    AppType.admin: AppConfiguration(
      appName: 'Admin Panel',
      primaryColor: 0xFF6A1B9A, // Purple
      appId: 'com.grocery.admin',
      features: ['management', 'analytics', 'users'],
    ),
  };

  /// Get current app configuration
  static AppConfiguration get current => _configs[currentApp]!;

  /// Get configuration for specific app type
  static AppConfiguration getConfig(AppType appType) => _configs[appType]!;

  /// Switch app type (for development/testing)
  static void switchApp(AppType appType) {
    currentApp = appType;
  }

  /// Check if current app has specific feature
  static bool hasFeature(String feature) {
    return current.features.contains(feature);
  }

  /// Get app type from string (useful for deep links/routing)
  static AppType? getAppTypeFromString(String appTypeString) {
    switch (appTypeString.toLowerCase()) {
      case 'customer':
        return AppType.customer;
      case 'store':
        return AppType.store;
      case 'shipper':
        return AppType.shipper;
      case 'admin':
        return AppType.admin;
      default:
        return null;
    }
  }

  /// Convert AppType to string
  static String getStringFromAppType(AppType appType) {
    return appType.name;
  }
}

/// Configuration class for each app
class AppConfiguration {
  final String appName;
  final int primaryColor;
  final String appId;
  final List<String> features;

  const AppConfiguration({
    required this.appName,
    required this.primaryColor,
    required this.appId,
    required this.features,
  });
}

/// Extension for AppType utility methods
extension AppTypeExtension on AppType {
  String get displayName {
    switch (this) {
      case AppType.customer:
        return 'Customer';
      case AppType.store:
        return 'Store Owner';
      case AppType.shipper:
        return 'Shipper';
      case AppType.admin:
        return 'Administrator';
    }
  }

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

  /// Get app-specific routes
  List<String> get allowedRoutes {
    switch (this) {
      case AppType.customer:
        return ['/home', '/products', '/orders', '/profile'];
      case AppType.store:
        return ['/dashboard', '/inventory', '/orders', '/analytics'];
      case AppType.shipper:
        return ['/dashboard', '/available-orders', '/my-deliveries'];
      case AppType.admin:
        return ['/admin', '/users', '/stores', '/reports'];
    }
  }
}