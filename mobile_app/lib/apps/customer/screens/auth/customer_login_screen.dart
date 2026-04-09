import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/customer_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';

import '../../bloc/customer_auth_bloc.dart';
import '../home/customer_home_screen.dart';
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
  Widget build(BuildContext context) {
    return BlocListener<CustomerAuthBloc, CustomerAuthState>(
      listener: (context, state) {
        if (state is CustomerAuthLoading) {
          setState(() => _isLoading = true);
        }

        if (state is CustomerAuthSuccess) {
          setState(() => _isLoading = false);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        }

        if (state is CustomerAuthFailure) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
        'Đăng nhập để bắt đầu mua sắm.',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    ],
  );

  Widget _buildLoginForm() => Column(
    children: [
      CustomTextField(
        label: 'Số điện thoại',
        hint: 'Nhập số điện thoại',
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
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Đăng nhập"),
    ),
  );

  Widget _buildRegisterLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Chưa có tài khoản? "),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerRegisterScreen()),
          );
        },
        child: const Text(
          "Đăng ký",
          style: TextStyle(
            color: CustomerTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );

  Widget _buildForgotPasswordLink() => const Center(
    child: Text(
      "Quên mật khẩu?",
      style: TextStyle(color: CustomerTheme.primaryColor),
    ),
  );

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Nhập số điện thoại";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Nhập mật khẩu";
    }
    return null;
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CustomerAuthBloc>().add(
      CustomerLoginEvent(_phoneController.text, _passwordController.text),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
