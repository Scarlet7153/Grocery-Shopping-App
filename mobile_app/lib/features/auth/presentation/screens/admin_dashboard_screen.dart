import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/bloc/auth_event.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Quản trị'),
        backgroundColor: const Color(0xFF6A1B9A), // Màu tím Admin
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Xin chào, ${user.fullName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vai trò: ${user.role.name.toUpperCase()}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Chức năng hệ thống',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // QUẢN LÝ QUYỀN: Các widget này chỉ hiện khi user có quyền tương ứng
                if (state.hasPermission('manage_users'))
                  _buildFeatureCard(
                    context,
                    'Quản lý người dùng',
                    Icons.people,
                    Colors.blue,
                  ),

                if (state.hasPermission('manage_stores'))
                  _buildFeatureCard(
                    context,
                    'Quản lý cửa hàng',
                    Icons.store,
                    Colors.green,
                  ),

                if (state.hasPermission('view_analytics'))
                  _buildFeatureCard(
                    context,
                    'Thống kê & Báo cáo',
                    Icons.bar_chart,
                    Colors.orange,
                  ),

                if (state.hasPermission('system_settings'))
                  _buildFeatureCard(
                    context,
                    'Cài đặt hệ thống',
                    Icons.settings,
                    Colors.grey,
                  ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Mở chức năng: $title')));
        },
      ),
    );
  }
}
