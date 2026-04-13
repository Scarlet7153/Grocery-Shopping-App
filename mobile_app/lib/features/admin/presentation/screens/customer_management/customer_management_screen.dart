import 'package:flutter/material.dart';
import '../../../../auth/models/user_model.dart';
import '../user_management/user_management_screen.dart';

class CustomerManagementScreen extends StatelessWidget {
  const CustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản lý Khách hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCustomerStats(),
          const Expanded(
            child: UserManagementScreen(initialRole: UserRole.customer),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF8F9FA),
      child: Row(
        children: [
          _buildStatCard('Tổng Khách', '2,450', Icons.people, Colors.blue),
          _buildStatCard('Mới hôm nay', '12', Icons.person_add, Colors.green),
          _buildStatCard('Đang hoạt động', '1,120', Icons.check_circle, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
