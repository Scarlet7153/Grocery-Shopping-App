import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../widgets/role_selection_card.dart';

/// Screen for selecting user role (Customer, Store Owner, Shipper)
/// Admin login is handled separately in web interface
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  UserRole? selectedRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingLarge),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacing4Xl),
          _buildHeader(),
          const SizedBox(height: AppDimensions.spacing5Xl),
          _buildRoleSelection(),
          const SizedBox(height: AppDimensions.spacing4Xl),
          _buildContinueButton(),
          const SizedBox(height: AppDimensions.spacing2Xl),
          _buildAdminNote(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo/Icon
        Container(
          width: AppDimensions.icon3Xl,
          height: AppDimensions.icon3Xl,
          decoration: BoxDecoration(
            gradient: AppColors.storeGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.storePrimary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            size: AppDimensions.iconXl,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing2Xl),
        
        // Welcome Text
        Text(
          'Chào mừng đến với',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        Text(
          'App Đi Chợ Hộ',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.storePrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        
        Text(
          'Vui lòng chọn vai trò của bạn để tiếp tục',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    final mobileRoles = UserRole.mobileRoles;
    
    return Column(
      children: mobileRoles.asMap().entries.map((entry) {
        final index = entry.key;
        final role = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < mobileRoles.length - 1 
                ? AppDimensions.spacingL 
                : 0,
          ),
          child: RoleSelectionCard(
            role: role,
            isSelected: selectedRole == role,
            onTap: () => _selectRole(role),
            animationDelay: Duration(
              milliseconds: AppDimensions.animationFast * (index + 1),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Tiếp tục',
        onPressed: selectedRole != null ? _handleContinue : null,
        type: ButtonType.primary,
        size: ButtonSize.large,
        customColor: selectedRole?.primaryColor,
        isLoading: false,
      ),
    );
  }

  Widget _buildAdminNote() {
    return Column(
      children: [
        const Divider(
          thickness: AppDimensions.dividerThickness,
          color: AppColors.divider,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        Text(
          'Quản trị viên?',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        TextButton.icon(
          onPressed: _navigateToAdminLogin,
          icon: const Icon(
            Icons.admin_panel_settings_outlined,
            size: AppDimensions.iconS,
          ),
          label: const Text('Đăng nhập Admin'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.adminPrimary,
          ),
        ),
      ],
    );
  }

  void _selectRole(UserRole role) {
    setState(() {
      selectedRole = role;
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _handleContinue() {
    if (selectedRole == null) return;
    
    // Navigate to login screen for selected role
    Navigator.pushNamed(
      context, 
      '/login',
      arguments: selectedRole,
    );
  }

  void _navigateToAdminLogin() {
    // Navigate to admin login (web interface or special admin flow)
    Navigator.pushNamed(context, '/admin-login');
  }
}
