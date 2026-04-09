import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminTheme.backgroundColor,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildSecurityNotice(),
              const SizedBox(height: 32),
              _buildLoginForm(),
              const SizedBox(height: 32),
              _buildLoginButton(),
              const SizedBox(height: 24),
              _buildContactSupport(),
              const SizedBox(height: 32),
              _buildAdminFeatures(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Admin crown icon với premium design
      Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminTheme.primaryColor.withValues(alpha: 0.1),
                  AdminTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AdminTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: AdminTheme.primaryColor,
            ),
          ),
          // Crown indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.diamond, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        'Admin Panel Access',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AdminTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Chỉ dành cho quản trị viên được ủy quyền.',
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
      ),
    ],
  );

  Widget _buildSecurityNotice() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.amber.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.security, color: Colors.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Khu vực bảo mật cao',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Tài khoản Admin được cấp bởi Super Admin',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildLoginForm() => Column(
    children: [
      CustomTextField(
        label: 'Email Admin',
        hint: 'admin@dichho.com',
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        prefixIcon: Icons.email,
        validator: _validateAdminEmail,
        focusColor: AdminTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Mật khẩu Admin',
        hint: 'Nhập mật khẩu được cấp',
        controller: _passwordController,
        isPassword: true,
        prefixIcon: Icons.lock,
        validator: _validatePassword,
        focusColor: AdminTheme.primaryColor,
      ),
    ],
  );

  Widget _buildLoginButton() => Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AdminTheme.primaryColor, AdminTheme.secondaryColor],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AdminTheme.primaryColor.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 20),
                SizedBox(width: 8),
                Text(
                  'Truy cập Admin Panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    ),
  );

  Widget _buildContactSupport() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AdminTheme.primaryColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AdminTheme.primaryColor.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.help_center,
              color: AdminTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Cần hỗ trợ truy cập?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Liên hệ Super Admin hoặc IT Department để được cấp tài khoản Admin',
          style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildContactButton(
                icon: Icons.phone,
                text: 'Gọi IT: 1900-xxx',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng gọi điện đang phát triển'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildContactButton(
                icon: Icons.email,
                text: 'Email IT',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email: it@dichho.com')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildContactButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AdminTheme.primaryColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AdminTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAdminFeatures() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AdminTheme.primaryColor.withValues(alpha: 0.05),
          AdminTheme.secondaryColor.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AdminTheme.primaryColor.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.diamond, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Admin Panel Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildFeatureGrid(),
      ],
    ),
  );

  Widget _buildFeatureGrid() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.dashboard,
              title: 'System Dashboard',
              description: 'Tổng quan hệ thống',
              color: AdminTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.analytics,
              title: 'Analytics',
              description: 'Báo cáo & thống kê',
              color: Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.people,
              title: 'User Management',
              description: 'Quản lý người dùng',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.settings,
              title: 'System Settings',
              description: 'Cấu hình hệ thống',
              color: Colors.grey[700]!,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    ),
  );

  String? _validateAdminEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email Admin';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Định dạng email không hợp lệ';
    }
    // Admin email validation - stricter rules
    if (!value.toLowerCase().contains('admin') &&
        !value.toLowerCase().contains('@dichho.com')) {
      return 'Email không phải tài khoản Admin hệ thống';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu Admin';
    }
    if (value.length < 8) {
      return 'Mật khẩu Admin phải có ít nhất 8 ký tự';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Mock admin login API call với validation nghiêm ngặt
      await Future.delayed(const Duration(seconds: 2));

      // Mock admin credentials check
      final email = _emailController.text.toLowerCase();
      final password = _passwordController.text;

      // Demo admin accounts
      if ((email == 'admin@dichoho.com' && password == 'admin123') ||
          (email == 'superadmin@dichoho.com' && password == 'super123')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Đăng nhập Admin thành công! Chào mừng đến Admin Panel',
              ),
              backgroundColor: AdminTheme.primaryColor,
              duration: Duration(seconds: 3),
            ),
          );
          // TODOhehe: Navigate to admin dashboard
        }
      } else {
        throw 'Thông tin đăng nhập Admin không chính xác';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
