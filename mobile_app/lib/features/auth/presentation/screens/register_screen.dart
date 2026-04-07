import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/location/province_api.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Register screen for different user roles
/// Design adapted from Figma with role-specific theming and validation
class RegisterScreen extends StatefulWidget {
  final UserRole userRole;

  const RegisterScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Store specific fields
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _businessLicenseController = TextEditingController();

  final _provinceApi = ProvinceApi();
  List<LocationItem> _provinces = [];
  List<LocationItem> _districts = [];
  List<LocationItem> _wards = [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedDistrict;
  LocationItem? _selectedWard;
  bool _isLoadingLocation = false;
  
  bool _isLoading = false;
  bool _agreeToTerms = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProvinces();
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

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingLocation = true);
    try {
      _provinces = await _provinceApi.getProvinces();
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _onProvinceChanged(LocationItem? item) async {
    setState(() {
      _selectedProvince = item;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = [];
      _wards = [];
    });
    _updateAddressText();
    if (item == null) return;
    final districts = await _provinceApi.getDistricts(item.code);
    if (mounted) {
      setState(() => _districts = districts);
    }
  }

  Future<void> _onDistrictChanged(LocationItem? item) async {
    setState(() {
      _selectedDistrict = item;
      _selectedWard = null;
      _wards = [];
    });
    _updateAddressText();
    if (item == null) return;
    final wards = await _provinceApi.getWards(item.code);
    if (mounted) {
      setState(() => _wards = wards);
    }
  }

  void _onWardChanged(LocationItem? item) {
    setState(() => _selectedWard = item);
    _updateAddressText();
  }

  void _updateAddressText() {
    final parts = [
      _selectedWard?.name,
      _selectedDistrict?.name,
      _selectedProvince?.name,
    ].where((e) => e != null && e!.isNotEmpty).map((e) => e!).toList();
    _addressController.text = parts.join(', ');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _businessLicenseController.dispose();
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
            const SizedBox(height: AppDimensions.spacing4Xl),
            _buildRegistrationForm(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildTermsAndConditions(),
            const SizedBox(height: AppDimensions.spacing3Xl),
            _buildRegisterButton(),
            const SizedBox(height: AppDimensions.spacing2Xl),
            _buildLoginSection(),
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
        
        // Registration Title
        Text(
          'Tạo tài khoản mới',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        
        // Role-specific subtitle
        Text(
          'Đăng ký tài khoản ${widget.userRole.displayName.toLowerCase()}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        
        // Description
        Text(
          _getRoleRegistrationDescription(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.userRole.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        // Personal Information Section
        _buildSectionTitle('Thông tin cá nhân'),
        const SizedBox(height: AppDimensions.spacingL),
        
        _buildPersonalInfoFields(),
        
        // Role-specific fields
        if (widget.userRole == UserRole.store) ...[
          const SizedBox(height: AppDimensions.spacing2Xl),
          _buildSectionTitle('Thông tin cửa hàng'),
          const SizedBox(height: AppDimensions.spacingL),
          _buildStoreInfoFields(),
        ],
        
        // Security Section
        const SizedBox(height: AppDimensions.spacing2Xl),
        _buildSectionTitle('Thông tin bảo mật'),
        const SizedBox(height: AppDimensions.spacingL),
        
        _buildSecurityFields(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: widget.userRole.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Họ và tên',
          hint: 'Nhập họ và tên đầy đủ',
          prefixIcon: Icons.person_outline,
          validator: _validateName,
          focusColor: widget.userRole.primaryColor,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        CustomTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          validator: _validatePhone,
          focusColor: widget.userRole.primaryColor,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Nhập địa chỉ email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: _validateEmail,
          focusColor: widget.userRole.primaryColor,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        _buildLocationPicker(),
      ],
    );
  }

  Widget _buildStoreInfoFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _storeNameController,
          label: 'Tên cửa hàng',
          hint: 'Nhập tên cửa hàng',
          prefixIcon: Icons.store_outlined,
          validator: _validateStoreName,
          focusColor: widget.userRole.primaryColor,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        CustomTextField(
          controller: _storeAddressController,
          label: 'Địa chỉ cửa hàng',
          hint: 'Nhập địa chỉ cửa hàng',
          prefixIcon: Icons.business_outlined,
          validator: _validateStoreAddress,
          focusColor: widget.userRole.primaryColor,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        CustomTextField(
          controller: _businessLicenseController,
          label: 'Giấy phép kinh doanh',
          hint: 'Nhập số giấy phép kinh doanh (nếu có)',
          prefixIcon: Icons.description_outlined,
          focusColor: widget.userRole.primaryColor,
        ),
      ],
    );
  }

  Widget _buildSecurityFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _passwordController,
          label: 'Mật khẩu',
          hint: 'Nhập mật khẩu',
          isPassword: true,
          prefixIcon: Icons.lock_outline,
          validator: _validatePassword,
          focusColor: widget.userRole.primaryColor,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Xác nhận mật khẩu',
          hint: 'Nhập lại mật khẩu',
          isPassword: true,
          prefixIcon: Icons.lock_outline,
          validator: _validateConfirmPassword,
          focusColor: widget.userRole.primaryColor,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      children: [
        _buildLocationDropdown(
          label: 'Tỉnh/Thành phố',
          value: _selectedProvince,
          items: _provinces,
          onChanged: _isLoadingLocation ? null : _onProvinceChanged,
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildLocationDropdown(
          label: 'Quận/Huyện',
          value: _selectedDistrict,
          items: _districts,
          onChanged: _selectedProvince == null ? null : _onDistrictChanged,
          prefixIcon: Icons.map_outlined,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildLocationDropdown(
          label: 'Phường/Xã',
          value: _selectedWard,
          items: _wards,
          onChanged: _selectedDistrict == null ? null : _onWardChanged,
          prefixIcon: Icons.place_outlined,
          validator: (value) {
            if (value == null) {
              return 'Vui lòng chọn địa chỉ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationDropdown({
    required String label,
    required List<LocationItem> items,
    required IconData prefixIcon,
    LocationItem? value,
    FormFieldValidator<LocationItem>? validator,
    ValueChanged<LocationItem?>? onChanged,
  }) {
    return DropdownButtonFormField<LocationItem>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem<LocationItem>(
                value: item,
                child: Text(item.name),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'Tôi đồng ý với ',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.userRole.primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(
                  text: ' và ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.userRole.primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(
                  text: ' của ứng dụng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Tạo tài khoản',
        onPressed: _agreeToTerms ? _handleRegister : null,
        isLoading: _isLoading,
        type: ButtonType.primary,
        size: ButtonSize.large,
        customColor: widget.userRole.primaryColor,
      ),
    );
  }

  Widget _buildLoginSection() {
    return Column(
      children: [
        const Divider(
          thickness: AppDimensions.dividerThickness,
          color: AppColors.divider,
        ),
        const SizedBox(height: AppDimensions.spacing2Xl),
        
        RichText(
          text: TextSpan(
            text: 'Đã có tài khoản? ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: 'Đăng nhập ngay',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.userRole.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Đăng nhập',
            onPressed: _handleNavigateToLogin,
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

  String _getRoleRegistrationDescription() {
    switch (widget.userRole) {
      case UserRole.customer:
        return 'Đặt hàng và mua sắm trực tuyến dễ dàng';
      case UserRole.store:
        return 'Quản lý cửa hàng và bán hàng trực tuyến';
      case UserRole.shipper:
        return 'Nhận đơn hàng và giao hàng cho khách hàng';
      case UserRole.admin:
        return 'Quản trị và vận hành hệ thống';
    }
  }

  // Validation Methods

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length != 10) {
      return 'Số điện thoại phải có 10 chữ số';
    }
    
    if (!cleaned.startsWith('0')) {
      return 'Số điện thoại phải bắt đầu bằng số 0';
    }
    
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Vui lòng nhập email hợp lệ';
    }
    
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ';
    }
    if (value.trim().length < 5) {
      return 'Địa chỉ phải có ít nhất 5 ký tự';
    }
    return null;
  }

  String? _validateStoreName(String? value) {
    if (widget.userRole != UserRole.store) return null;
    
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên cửa hàng';
    }
    if (value.trim().length < 2) {
      return 'Tên cửa hàng phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validateStoreAddress(String? value) {
    if (widget.userRole != UserRole.store) return null;
    
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ cửa hàng';
    }
    if (value.trim().length < 5) {
      return 'Địa chỉ cửa hàng phải có ít nhất 5 ký tự';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Mật khẩu phải chứa chữ hoa, chữ thường và số';
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

  // Action Handlers

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // TODOhehe: Implement actual registration API call
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Đăng ký thất bại: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleNavigateToLogin() {
    Navigator.pop(context);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: const Icon(
          Icons.check_circle,
          size: AppDimensions.iconXl,
          color: AppColors.success,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đăng ký thành công!',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'Tài khoản ${widget.userRole.displayName.toLowerCase()} đã được tạo thành công.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Đăng nhập ngay',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            type: ButtonType.primary,
            customColor: widget.userRole.primaryColor,
          ),
        ],
      ),
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
