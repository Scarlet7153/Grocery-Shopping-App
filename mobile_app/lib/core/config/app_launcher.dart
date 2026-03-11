import 'package:flutter/material.dart';
import 'app_config.dart';

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose App'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: AppType.values.map((appType) {
            final config = AppConfig.getConfig(appType);
            return _buildAppCard(context, appType, config);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppType appType, AppConfiguration config) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _launchApp(context, appType),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(config.primaryColor),
                Color(config.primaryColor).withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getAppIcon(appType),
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                config.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                appType.displayName,
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

  void _launchApp(BuildContext context, AppType appType) {
    AppConfig.switchApp(appType);
    
    // Navigate to the selected app
    Navigator.of(context).pushReplacementNamed('/app');
  }
}