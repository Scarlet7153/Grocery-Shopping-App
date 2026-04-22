import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import '../../../../auth/models/user_model.dart';
import '../user_management/user_management_screen.dart';

class CustomerManagementScreen extends StatelessWidget {
  const CustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.byLocale(vi: 'Quản lý Khách hàng', en: 'Customer management'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCustomerStats(context),
          const Expanded(
            child: UserManagementScreen(initialRole: UserRole.customer),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          _buildStatCard(context, AppLocalizations.of(context)!.byLocale(vi: 'Tổng Khách', en: 'Total customers'), '2,450', Icons.people, Colors.blue),
          _buildStatCard(context, AppLocalizations.of(context)!.byLocale(vi: 'Mới hôm nay', en: 'New today'), '12', Icons.person_add, Colors.green),
          _buildStatCard(context, AppLocalizations.of(context)!.byLocale(vi: 'Đang hoạt động', en: 'Active now'), '1,120', Icons.check_circle, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(title, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
