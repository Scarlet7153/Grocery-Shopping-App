import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import 'package:grocery_shopping_app/shared/widgets/custom_text_field.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_auth_bloc.dart';
import 'package:grocery_shopping_app/apps/shipper/repository/shipper_repository.dart';
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

  String _tr(String vi, String en) {
    final l = AppLocalizations.of(context) ??
        AppLocalizations(Localizations.localeOf(context));
    return l.byLocale(vi: vi, en: en);
  }

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
          _handleAuthSuccess();
        }

        if (state is ShipperAuthError) {
          _handleLoginError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
      Text(
        _tr('Chào mừng Shipper!', 'Welcome, Shipper!'),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ShipperTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _tr(
          'Đăng nhập để bắt đầu nhận đơn và kiếm thu nhập hấp dẫn.',
          'Sign in to start receiving orders and earning attractive income.',
        ),
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
      ),
    ],
  );

  Widget _buildLoginForm() => Column(
    children: [
      _buildPhoneField(),
      const SizedBox(height: 20),
      _buildPasswordField(),
    ],
  );

  Widget _buildPhoneField() => CustomTextField(
    label: _tr('Số điện thoại', 'Phone number'),
    hint: _tr('Nhập số điện thoại đã đăng ký', 'Enter your registered phone number'),
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    prefixIcon: Icons.phone,
    focusColor: ShipperTheme.primaryColor,
  );

  Widget _buildPasswordField() => CustomTextField(
    label: _tr('Mật khẩu', 'Password'),
    hint: _tr('Nhập mật khẩu', 'Enter your password'),
    controller: _passwordController,
    isPassword: true,
    prefixIcon: Icons.lock,
    focusColor: ShipperTheme.primaryColor,
  );

  Widget _buildLoginButton() => Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _isLoading
            ? [
                ShipperTheme.primaryColor.withValues(alpha: 0.75),
                ShipperTheme.secondaryColor.withValues(alpha: 0.75),
              ]
            : const [ShipperTheme.primaryColor, ShipperTheme.secondaryColor],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: ShipperTheme.primaryColor.withValues(
            alpha: _isLoading ? 0.2 : 0.35,
          ),
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
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.82),
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.motorcycle, size: 20),
                const SizedBox(width: 8),
                Text(
                  _tr('Bắt đầu giao hàng', 'Start delivering'),
                  style: const TextStyle(
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
        _tr('Chưa có tài khoản Shipper? ', 'Don\'t have a shipper account? '),
        style: TextStyle(color: Colors.grey[600]),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ShipperRegisterScreen(),
          ),
        ),
        child: Text(
          _tr('Đăng ký ngay', 'Sign up now'),
          style: const TextStyle(
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
          SnackBar(content: Text(_tr('Tính năng đang phát triển', 'Feature in development'))),
        );
      },
      child: Text(
        _tr('Quên mật khẩu?', 'Forgot password?'),
        style: const TextStyle(
          color: ShipperTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return _tr('Vui lòng nhập số điện thoại', 'Please enter your phone number');
    }
    if (value.length != 10 || !RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
      return _tr(
        'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)',
        'Invalid phone number (10 digits, starts with 0)',
      );
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return _tr('Vui lòng nhập mật khẩu', 'Please enter your password');
    }
    if (value.length < 6) {
      return _tr('Mật khẩu phải có ít nhất 6 ký tự', 'Password must be at least 6 characters');
    }
    return null;
  }

  Future<void> _handleAuthSuccess() async {
    String? shipperName;
    try {
      final userData = await context.read<ShipperRepository>().getCurrentUser();
      final name = userData?['fullName']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        shipperName = name;
      }
    } catch (_) {
      // Fallback to generic welcome text if profile fetch fails.
    }

    if (!mounted) return;

    final welcomeMessage = shipperName != null
        ? _tr(
            'Đăng nhập thành công! Chào mừng $shipperName!',
            'Login successful! Welcome, $shipperName!',
          )
        : _tr(
            'Đăng nhập thành công! Chào mừng bạn!',
            'Login successful! Welcome!',
          );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(welcomeMessage),
        backgroundColor: ShipperTheme.primaryColor,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ShipperDashboardScreen()),
    );
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final phoneError = _validatePhone(phone);
    if (phoneError != null) {
      _showErrorSnackBar(message: phoneError, icon: Icons.phone_android);
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      _showErrorSnackBar(message: passwordError, icon: Icons.lock_outline);
      return;
    }

    _authBloc.add(
      ShipperLoginRequested(
        phone: phone,
        password: password,
      ),
    );
  }

  void _handleLoginError(String message) {
    setState(() {
      _isLoading = false;
    });

    if (message == 'null' || message.isEmpty) {
      message = _tr('Thông tin đăng nhập không chính xác', 'Incorrect login information');
    }

    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }

    debugPrint('Login error: $message');

    final lowerMessage = message.toLowerCase().trim();

    IconData icon = Icons.error_outline;
    Duration duration = const Duration(seconds: 3);

    if (lowerMessage.contains('số điện thoại chưa được đăng ký') ||
        lowerMessage.contains('không tìm thấy tài khoản') ||
        lowerMessage.contains('not found')) {
      message = _tr('Số điện thoại chưa được đăng ký', 'Phone number is not registered');
      icon = Icons.phone_android;
    } else if (lowerMessage.contains('thông tin đăng nhập không hợp lệ') ||
        lowerMessage.contains('sai số điện thoại hoặc mật khẩu') ||
        lowerMessage.contains('sai mật khẩu') ||
        lowerMessage.contains('bad credentials') ||
        lowerMessage.contains('unauthorized')) {
      message = _tr('Sai số điện thoại hoặc mật khẩu', 'Wrong phone number or password');
      icon = Icons.lock_outline;
    } else if (lowerMessage.contains('tài khoản chưa được kích hoạt') ||
        lowerMessage.contains('inactive') ||
        lowerMessage.contains('not activated')) {
      message = _tr(
        'Tài khoản chưa được kích hoạt. Vui lòng kiểm tra email hoặc liên hệ hỗ trợ.',
        'Account is not activated. Please check email or contact support.',
      );
      icon = Icons.mail_outline;
    } else if (lowerMessage.contains('tài khoản đã bị khóa') ||
        lowerMessage.contains('banned') ||
        lowerMessage.contains('blocked')) {
      message = _tr(
        'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
        'Account is blocked. Please contact administrator.',
      );
      icon = Icons.block;
    }

    _showErrorSnackBar(message: message, icon: icon, duration: duration);
  }

  void _showErrorSnackBar({
    required String message,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
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
