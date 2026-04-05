import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../enums/app_type.dart'; // Import để sử dụng Enum và Extension displayName
import 'app_config.dart';
=======
import '../../../core/enums/app_type.dart';

class AppConfiguration {
  final int primaryColor;
  final String appName;
  final String appId;
  final List<String> allowedRoutes;

  const AppConfiguration({
    required this.primaryColor,
    required this.appName,
    required this.appId,
    this.allowedRoutes = const [],
  });
}

class AppConfig {
  static AppType currentApp = AppType.customer;

  static final Map<AppType, AppConfiguration> _configs = {
    AppType.customer: const AppConfiguration(
      primaryColor: 0xFF4CAF50,
      appName: 'Đi Chợ Hộ - Khách Hàng',
      appId: 'com.dichohho.customer',
      allowedRoutes: ['/home', '/auth'],
    ),
    AppType.store: const AppConfiguration(
      primaryColor: 0xFF2196F3,
      appName: 'Đi Chợ Hộ - Chủ Cửa Hàng',
      appId: 'com.dichohho.store',
      allowedRoutes: ['/store', '/auth'],
    ),
    AppType.shipper: const AppConfiguration(
      primaryColor: 0xFFFF9800,
      appName: 'Đi Chợ Hộ - Shipper',
      appId: 'com.dichohho.shipper',
      allowedRoutes: ['/shipper', '/auth'],
    ),
    AppType.admin: const AppConfiguration(
      primaryColor: 0xFF9C27B0,
      appName: 'Đi Chợ Hộ - Quản Trị Viên',
      appId: 'com.dichohho.admin',
      allowedRoutes: ['/admin', '/auth'],
    ),
  };

  static AppConfiguration getConfig(AppType type) => _configs[type]!;
  static AppConfiguration get current => getConfig(currentApp);
  static void switchApp(AppType type) => currentApp = type;

  static String get appName => current.appName;
  static String get appId => current.appId;
}
>>>>>>> mobile_app

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  /// Helper cung cấp màu và tên riêng cho Launcher 
  /// (Vì AppConfig hiện tại chỉ chứa thông tin của App đang build)
  Map<String, dynamic> _getAppUIInfo(AppType type) {
    switch (type) {
      case AppType.customer:
        return {'name': 'Khách Hàng', 'color': 0xFF2E7D32}; // Màu xanh lá
      case AppType.store:
        return {'name': 'Cửa Hàng', 'color': 0xFF1565C0};   // Màu xanh dương
      case AppType.shipper:
        return {'name': 'Giao Hàng', 'color': 0xFFE65100};  // Màu cam
      case AppType.admin:
        return {'name': 'Quản Trị Viên', 'color': 0xFF6A1B9A}; // Màu tím
    }
  }

  @override
  Widget build(BuildContext context) {
    const apps = AppType.values; // use const to satisfy prefer_const_declarations
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Menu: Khởi động App'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
<<<<<<< HEAD
          children: AppType.values.map((appType) {
            final uiInfo = _getAppUIInfo(appType);
            return _buildAppCard(context, appType, uiInfo);
=======
          children: apps.map((appType) {
            final config = AppConfig.getConfig(appType);
            return _buildAppCard(context, appType, config);
>>>>>>> mobile_app
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppType appType, Map<String, dynamic> uiInfo) {
    final Color primaryColor = Color(uiInfo['color']);
    final String appName = uiInfo['name'];

    return Card(
      elevation: 4,
<<<<<<< HEAD
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _launchApp(context, appType, appName, primaryColor),
        borderRadius: BorderRadius.circular(12),
=======
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _launchApp(context, appType),
>>>>>>> mobile_app
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
<<<<<<< HEAD
            borderRadius: BorderRadius.circular(12),
=======
>>>>>>> mobile_app
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
<<<<<<< HEAD
                primaryColor,
                primaryColor.withValues(alpha: 0.7),
=======
                Color(config.primaryColor),
                // avoid deprecated withOpacity; use withAlpha (191 == 0.75*255)
                Color(config.primaryColor).withAlpha(191),
>>>>>>> mobile_app
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getAppIcon(appType),
                size: 42,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
<<<<<<< HEAD
                appType.displayName, // Đã hoạt động nhờ extension bên app_type.dart
=======
                // directly use display helper (remove unnecessary type-check)
                _displayName(appType),
>>>>>>> mobile_app
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAppIcon(AppType appType) {
    switch (appType) {
      case AppType.customer:
        return Icons.shopping_cart;
      case AppType.store:
        return Icons.store;
      case AppType.shipper:
        return Icons.local_shipping;
      case AppType.admin:
        return Icons.admin_panel_settings;
    }
  }

<<<<<<< HEAD
  void _launchApp(BuildContext context, AppType appType, String appName, Color color) {
    // Lưu ý: Không thể dùng AppConfig.switchApp(appType) vì ứng dụng đã fix cứng 
    // AppType lúc biên dịch qua String.fromEnvironment.
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang mô phỏng mở app $appName...'),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Tuỳ vào file main.dart, bạn có thể đẩy người dùng về Route của app đó
    // Navigator.of(context).pushReplacementNamed('/${appType.name}');
=======
  String _displayName(AppType appType) {
    try {
      final dynamic dyn = appType;
      final value = dyn.displayName;
      if (value is String) return value;
    } catch (_) {}
    final parts = appType.toString().split('.');
    return parts.isNotEmpty ? _capitalize(parts.last) : appType.toString();
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void _launchApp(BuildContext context, AppType appType) {
    AppConfig.switchApp(appType);
    Navigator.of(context).pushReplacementNamed('/app');
>>>>>>> mobile_app
  }
}