import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Login screen for different user roles
/// Design adapted from Figma with role-specific theming
class LoginScreen extends StatefulWidget {
  final UserRole userRole;

  const LoginScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationSlow),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.spacing5Xl),
            _buildLoginForm(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildRememberMeRow(),
            const SizedBox(height: AppDimensions.spacing3Xl),
            _buildLoginButton(),
            const SizedBox(height: AppDimensions.spacing2Xl),
            _buildForgotPassword(),
            const SizedBox(height: AppDimensions.spacing4Xl),
            _buildRegisterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Icon
        Container(
          width: AppDimensions.iconXl + 8,
          height: AppDimensions.iconXl + 8,
          decoration: BoxDecoration(
            gradient: widget.userRole.gradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: widget.userRole.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.userRole.iconFilled,
            size: AppDimensions.iconL,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing2Xl),
        
        // Welcome Title
        Text(
          'Chào mừng trở lại!',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        // Role-specific subtitle
        Text(
          'Đăng nhập vào tài khoản ${widget.userRole.displayName.toLowerCase()}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        
        // Description
        Text(
          widget.userRole.description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.userRole.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Phone Number Field
        CustomTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại của bạn',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          validator: _validatePhone,
          focusColor: widget.userRole.primaryColor,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        // Password Field
        CustomTextField(
          controller: _passwordController,
          label: 'Mật khẩu',
          hint: 'Nhập mật khẩu của bạn',
          isPassword: true,
          prefixIcon: Icons.lock_outline,
          validator: _validatePassword,
          focusColor: widget.userRole.primaryColor,
        ),
      ],
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return widget.userRole.primaryColor;
                }
                return null;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
            ),
          ),
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) => setState(() => _rememberMe = value ?? false),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          'Ghi nhớ đăng nhập',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Đăng nhập',
        onPressed: _handleLogin,
        isLoading: _isLoading,
        type: ButtonType.primary,
        size: ButtonSize.large,
        customColor: widget.userRole.primaryColor,
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          'Quên mật khẩu?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.userRole.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Column(
      children: [
        const Divider(
          thickness: AppDimensions.dividerThickness,
          color: AppColors.divider,
        ),
        const SizedBox(height: AppDimensions.spacing2Xl),
        
        // Register prompt
        RichText(
          text: TextSpan(
            text: 'Chưa có tài khoản? ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: 'Đăng ký ngay',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.userRole.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        // Register Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Tạo tài khoản mới',
            onPressed: _handleRegister,
            type: ButtonType.outline,
            size: ButtonSize.large,
            customColor: widget.userRole.primaryColor,
          ),
        ),
      ],
    );
  }

  // Helper Methods

  Color _getBackgroundColor() {
    return widget.userRole.containerColor.withValues(alpha: 0.05);
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    // Remove spaces and special characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length != 10) {
      return 'Số điện thoại phải có 10 chữ số';
    }
    
    if (!cleaned.startsWith('0')) {
      return 'Số điện thoại phải bắt đầu bằng số 0';
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
    HapticFeedback.lightImpact();

    try {
      // TODOhehe: Implement actual login API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Navigate to role-specific home screen
        _navigateToHome();
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Đăng nhập thất bại: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleForgotPassword() {
    Navigator.pushNamed(
      context,
      '/forgot-password',
      arguments: widget.userRole,
    );
  }

  void _handleRegister() {
    Navigator.pushNamed(
      context,
      '/register',
      arguments: widget.userRole,
    );
  }

  void _navigateToHome() {
    final homeRoute = switch (widget.userRole) {
      UserRole.customer => '/customer-home',
      UserRole.store => '/store-dashboard',
      UserRole.shipper => '/shipper-dashboard',
      UserRole.admin => '/admin-dashboard',
    };

    Navigator.pushNamedAndRemoveUntil(
      context,
      homeRoute,
      (route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }
}
