import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../home/store_home_screen.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';

import '../../block/store_auth_bloc.dart';
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
  Widget build(BuildContext context) {
    return BlocListener<StoreAuthBloc, StoreAuthState>(
      listener: (context, state) {
        if (state is StoreAuthLoading) {
          setState(() {
            _isLoading = true;
          });
        }

        if (state is StoreAuthSuccess) {
          setState(() {
            _isLoading = false;
          });

          final token = state.data["token"];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StoreHomeScreen(token: token)),
          );
        }

        if (state is StoreAuthError) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },

      child: Scaffold(
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
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
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
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
  }

  Widget _buildLoginButton() {
    return SizedBox(
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Text(
          'Chưa có tài khoản cửa hàng? ',
          style: TextStyle(color: Colors.grey[600]),
        ),

        GestureDetector(
          onTap: () async {
            final msg = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const StoreRegisterScreen()),
            );
            if (!context.mounted || msg == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: StoreTheme.primaryColor,
              ),
            );
          },

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
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
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
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    if (value.length != 10 || !RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
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

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<StoreAuthBloc>().add(
      LoginStoreEvent(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();

    super.dispose();
  }
}
