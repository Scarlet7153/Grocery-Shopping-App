import 'package:flutter/material.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import 'store_register_screen.dart';

class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});

  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: StoreTheme.backgroundColor,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildLoginForm(),
              const SizedBox(height: 32),
              _buildLoginButton(),
              const SizedBox(height: 16),
              _buildRegisterLink(),
              const SizedBox(height: 16),
              _buildForgotPasswordLink(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Store icon với background
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StoreTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.store,
          size: 48,
          color: StoreTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Chào mừng Chủ cửa hàng!',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: StoreTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Đăng nhập để quản lý cửa hàng và bán hàng hiệu quả.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _buildLoginForm() => Column(
    children: [
      CustomTextField(
        label: 'Số điện thoại',
        hint: 'Nhập số điện thoại của cửa hàng',
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone,
        validator: _validatePhone,
        focusColor: StoreTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Mật khẩu',
        hint: 'Nhập mật khẩu',
        controller: _passwordController,
        isPassword: true,
        prefixIcon: Icons.lock,
        validator: _validatePassword,
        focusColor: StoreTheme.primaryColor,
      ),
    ],
  );

  Widget _buildLoginButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: StoreTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        : const Text(
            'Đăng nhập',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
    ),
  );

  Widget _buildRegisterLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Chưa có tài khoản cửa hàng? ',
        style: TextStyle(color: Colors.grey[600]),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StoreRegisterScreen()),
        ),
        child: const Text(
          'Đăng ký ngay',
          style: TextStyle(
            color: StoreTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _buildForgotPasswordLink() => Center(
    child: GestureDetector(
      onTap: () {
        // TODOhehe: Navigate to forgot password
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tính năng đang phát triển')),
        );
      },
      child: const Text(
        'Quên mật khẩu?',
        style: TextStyle(
          color: StoreTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (value.length != 10 || !RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Mock store login API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: StoreTheme.primaryColor,
          ),
        );
        // TODOhehe: Navigate to store home
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: $error'),
            backgroundColor: Colors.red,
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}