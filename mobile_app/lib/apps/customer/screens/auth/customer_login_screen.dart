import 'package:flutter/material.dart';
import '../../../../core/theme/customer_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import 'customer_register_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CustomerTheme.backgroundColor,
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
      // Customer icon với background
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CustomerTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.shopping_cart,
          size: 48,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Chào mừng trở lại!',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Đăng nhập để bắt đầu mua sắm và đặt hàng dễ dàng.',
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
        hint: 'Nhập số điện thoại của bạn',
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone,
        validator: _validatePhone,
        focusColor: CustomerTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Mật khẩu',
        hint: 'Nhập mật khẩu',
        controller: _passwordController,
        isPassword: true,
        prefixIcon: Icons.lock,
        validator: _validatePassword,
        focusColor: CustomerTheme.primaryColor,
      ),
    ],
  );

  Widget _buildLoginButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomerTheme.primaryColor,
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
        'Chưa có tài khoản? ',
        style: TextStyle(color: Colors.grey[600]),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerRegisterScreen()),
        ),
        child: const Text(
          'Đăng ký ngay',
          style: TextStyle(
            color: CustomerTheme.primaryColor,
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
      },
      child: const Text(
        'Quên mật khẩu?',
        style: TextStyle(
          color: CustomerTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
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
      // TODOhehe: Implement customer login API
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: CustomerTheme.primaryColor,
          ),
        );
        // TODOhehe: Navigate to customer home
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