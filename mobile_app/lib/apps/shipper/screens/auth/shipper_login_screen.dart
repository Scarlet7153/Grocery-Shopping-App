import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/shared/widgets/custom_text_field.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_auth_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/auth/shipper_register_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/auth/shipper_splash_screen.dart';
import 'package:grocery_shopping_app/apps/shipper/screens/dashboard/shipper_dashboard_screen.dart';

class ShipperLoginScreen extends StatefulWidget {
  const ShipperLoginScreen({super.key});

  @override
  State<ShipperLoginScreen> createState() => _ShipperLoginScreenState();
}

class _ShipperLoginScreenState extends State<ShipperLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late ShipperAuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<ShipperAuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
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
              content: Text('Đăng nhập thành công! Chào mừng Shipper!'),
              backgroundColor: ShipperTheme.primaryColor,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ShipperDashboardScreen()),
          );
        }

        if (state is ShipperAuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập thất bại: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: ShipperTheme.backgroundColor,
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
                  const SizedBox(height: 24),
                  _buildShipperBenefits(),
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
          // Shipper icon với delivery animation
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ShipperTheme.primaryColor.withValues(alpha: 0.1),
                      ShipperTheme.secondaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const ShipperLogo(size: 128),
              ),
              // Speed indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Chào mừng Shipper!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ShipperTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập để bắt đầu nhận đơn và kiếm thu nhập hấp dẫn.',
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
            hint: 'Nhập số điện thoại đã đăng ký',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
            validator: _validatePhone,
            focusColor: ShipperTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Mật khẩu',
            hint: 'Nhập mật khẩu',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock,
            validator: _validatePassword,
            focusColor: ShipperTheme.primaryColor,
          ),
        ],
      );

  Widget _buildLoginButton() => Container(
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
          onPressed: _isLoading ? null : _handleLogin,
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
                    Icon(Icons.motorcycle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bắt đầu giao hàng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      );

  Widget _buildRegisterLink() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Chưa có tài khoản Shipper? ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ShipperRegisterScreen()),
            ),
            child: const Text(
              'Đăng ký ngay',
              style: TextStyle(
                color: ShipperTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _buildForgotPasswordLink() => Center(
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng đang phát triển')),
            );
          },
          child: const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              color: ShipperTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildShipperBenefits() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ShipperTheme.primaryColor.withValues(alpha: 0.05),
              ShipperTheme.secondaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ShipperTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lợi ích khi làm Shipper',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              icon: Icons.attach_money,
              title: 'Thu nhập cao',
              description: 'Từ 500K-2M/ngày tùy theo số đơn',
            ),
            _buildBenefitItem(
              icon: Icons.schedule,
              title: 'Thời gian linh hoạt',
              description: 'Tự chọn ca làm việc phù hợp',
            ),
            _buildBenefitItem(
              icon: Icons.location_on,
              title: 'Khu vực gần nhà',
              description: 'Nhận đơn trong bán kính 5km',
            ),
          ],
        ),
      );

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: ShipperTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    // dispatch event
    _authBloc.add(ShipperLoginRequested(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    ));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
