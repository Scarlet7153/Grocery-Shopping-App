import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/shared/widgets/custom_text_field.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_auth_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/auth/shipper_login_screen.dart';

class ShipperRegisterScreen extends StatefulWidget {
  const ShipperRegisterScreen({super.key});

  @override
  State<ShipperRegisterScreen> createState() => _ShipperRegisterScreenState();
}

class _ShipperRegisterScreenState extends State<ShipperRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agreeToTerms = false;

  late ShipperAuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<ShipperAuthBloc>();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ShipperTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Đăng ký Shipper'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ShipperTheme.primaryColor,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildPersonalInfo(),
                  const SizedBox(height: 24),
                  _buildSecurityInfo(),
                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 32),
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ShipperTheme.primaryColor.withValues(alpha: 0.1),
                  ShipperTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_add,
              size: 32,
              color: ShipperTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Trở thành Shipper',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ShipperTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tham gia mạng lưới giao hàng và kiếm thu nhập ổn định',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      );

  Widget _buildPersonalInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin cá nhân', Icons.person),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Họ và tên *',
            hint: 'Nhập họ và tên đầy đủ',
            controller: _nameController,
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person,
            validator: _validateName,
            focusColor: ShipperTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Số điện thoại *',
            hint: 'Nhập số điện thoại',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
            validator: _validatePhone,
            focusColor: ShipperTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Địa chỉ (tùy chọn)',
            hint: 'Nhập địa chỉ của bạn',
            controller: _addressController,
            prefixIcon: Icons.location_on,
            focusColor: ShipperTheme.primaryColor,
            maxLines: 2,
          ),
        ],
      );

  Widget _buildSecurityInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Bảo mật', Icons.security),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Mật khẩu *',
            hint: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock,
            validator: _validatePassword,
            focusColor: ShipperTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Xác nhận mật khẩu *',
            hint: 'Nhập lại mật khẩu',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: _validateConfirmPassword,
            focusColor: ShipperTheme.primaryColor,
          ),
        ],
      );

  Widget _buildSectionTitle(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: ShipperTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ShipperTheme.primaryColor,
            ),
          ),
        ],
      );

  Widget _buildTermsCheckbox() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreeToTerms,
            onChanged: (value) =>
                setState(() => _agreeToTerms = value ?? false),
            activeColor: ShipperTheme.primaryColor,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  children: const [
                    TextSpan(text: 'Tôi đồng ý với '),
                    TextSpan(
                      text: 'Điều khoản dành cho Shipper',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' và '),
                    TextSpan(
                      text: 'Chính sách bảo mật',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ' của ứng dụng.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildRegisterButton() {
    return BlocListener<ShipperAuthBloc, ShipperAuthState>(
      listener: (context, state) {
        if (state is ShipperAuthLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is ShipperAuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Đăng ký thành công! Chào mừng bạn trở thành Shipper'),
              backgroundColor: ShipperTheme.primaryColor,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ShipperLoginScreen()),
            (route) => false,
          );
        }

        if (state is ShipperAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng ký thất bại: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              ShipperTheme.primaryColor,
              ShipperTheme.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ShipperTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: (_isLoading || !_agreeToTerms) ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
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
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.how_to_reg, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Đăng ký làm Shipper',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Đã có tài khoản? ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Đăng nhập ngay',
              style: TextStyle(
                color: ShipperTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản sử dụng')),
      );
      return;
    }

    _authBloc.add(ShipperRegisterRequested(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
