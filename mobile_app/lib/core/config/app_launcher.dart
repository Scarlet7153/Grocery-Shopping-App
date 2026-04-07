import 'package:flutter/material.dart';
import '../enums/app_type.dart';

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  /// Helper cung cấp màu và tên riêng cho Launcher 
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
          children: AppType.values.map((appType) {
            final uiInfo = _getAppUIInfo(appType);
            return _buildAppCard(context, appType, uiInfo);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppType appType, Map<String, dynamic> uiInfo) {
    final Color primaryColor = Color(uiInfo['color'] as int);
    final String appName = uiInfo['name'] as String;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _launchApp(context, appType, appName, primaryColor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                primaryColor.withAlpha(179), // 0.7 * 255
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForApp(appType),
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForApp(AppType type) {
    switch (type) {
      case AppType.customer:
        return Icons.shopping_bag;
      case AppType.store:
        return Icons.store;
      case AppType.shipper:
        return Icons.local_shipping;
      case AppType.admin:
        return Icons.admin_panel_settings;
    }
  }

  void _launchApp(BuildContext context, AppType appType, String appName, Color primaryColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Khởi động app: $appName'),
        backgroundColor: primaryColor,
      ),
    );
  }
}
