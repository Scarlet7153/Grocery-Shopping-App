import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocery_shopping_app/core/location/province_api.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
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
  final _streetController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ProvinceApi _provinceApi = ProvinceApi();

  List<LocationItem> _provinces = [];
  List<LocationItem> _wards = [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedWard;

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _agreeToTerms = false;
  String? _locationError;

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
    _loadProvinces();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    appBar: AppBar(
      title: Text(_tr('Đăng ký Shipper', 'Shipper Registration')),
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
      Text(
        _tr('Trở thành Shipper', 'Become a shipper'),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ShipperTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _tr(
          'Tham gia mạng lưới giao hàng và kiếm thu nhập ổn định',
          'Join the delivery network and earn stable income',
        ),
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
      ),
    ],
  );

  Widget _buildPersonalInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(_tr('Thông tin cá nhân', 'Personal information'), Icons.person),
      const SizedBox(height: 16),
      CustomTextField(
        label: _tr('Họ và tên *', 'Full name *'),
        hint: _tr('Nhập họ và tên đầy đủ', 'Enter your full name'),
        controller: _nameController,
        keyboardType: TextInputType.name,
        prefixIcon: Icons.person,
        validator: _validateName,
        focusColor: ShipperTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: _tr('Số điện thoại *', 'Phone number *'),
        hint: _tr('Nhập số điện thoại', 'Enter phone number'),
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone,
        validator: _validatePhone,
        focusColor: ShipperTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      if (_isLoadingLocation)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      _buildLocationDropdown(
        label: _tr('Tỉnh/Thành phố', 'Province/City'),
        value: _selectedProvince,
        items: _provinces,
        onChanged: _isLoadingLocation ? null : _onProvinceChanged,
        hintText: _tr('Chọn tỉnh/thành phố', 'Select province/city'),
      ),
      const SizedBox(height: 12),
      _buildLocationDropdown(
        label: _tr('Phường/Xã', 'Ward/Commune'),
        value: _selectedWard,
        items: _wards,
        onChanged: (_selectedProvince == null || _isLoadingLocation)
            ? null
            : _onWardChanged,
        hintText: _tr('Chọn phường/xã', 'Select ward/commune'),
      ),
      const SizedBox(height: 12),
      CustomTextField(
        label: _tr('Đường (tùy chọn)', 'Street (optional)'),
        hint: _tr('Nhập số nhà, tên đường', 'Enter house number, street name'),
        controller: _streetController,
        prefixIcon: Icons.location_on,
        focusColor: ShipperTheme.primaryColor,
        maxLines: 2,
      ),
      if (_locationError != null) ...[
        const SizedBox(height: 8),
        Text(
          _locationError!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );

  Widget _buildSecurityInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(_tr('Bảo mật', 'Security'), Icons.security),
      const SizedBox(height: 16),
      CustomTextField(
        label: _tr('Mật khẩu *', 'Password *'),
        hint: _tr('Nhập mật khẩu (tối thiểu 6 ký tự)', 'Enter password (at least 6 characters)'),
        controller: _passwordController,
        isPassword: true,
        prefixIcon: Icons.lock,
        validator: _validatePassword,
        focusColor: ShipperTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: _tr('Xác nhận mật khẩu *', 'Confirm password *'),
        hint: _tr('Nhập lại mật khẩu', 'Re-enter password'),
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
        onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
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
              children: [
                TextSpan(text: _tr('Tôi đồng ý với ', 'I agree to the ')),
                TextSpan(
                  text: _tr('Điều khoản dành cho Shipper', 'Shipper Terms'),
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: _tr(' và ', ' and ')),
                TextSpan(
                  text: _tr('Chính sách bảo mật', 'Privacy Policy'),
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: _tr(' của ứng dụng.', ' of the app.')),
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
            SnackBar(
              content: Text(
                _tr(
                  'Đăng ký thành công! Chào mừng bạn trở thành Shipper',
                  'Registration successful! Welcome aboard as a shipper',
                ),
              ),
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
              content: Text(
                '${_tr('Đăng ký thất bại', 'Registration failed')}: ${state.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: (_isLoading || !_agreeToTerms)
                ? [
                    ShipperTheme.primaryColor.withValues(alpha: 0.75),
                    ShipperTheme.secondaryColor.withValues(alpha: 0.75),
                  ]
                : const [
                    ShipperTheme.primaryColor,
                    ShipperTheme.secondaryColor,
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ShipperTheme.primaryColor.withValues(
                alpha: (_isLoading || !_agreeToTerms) ? 0.2 : 0.35,
              ),
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
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.82),
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
                  : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                        const Icon(Icons.how_to_reg, size: 20),
                        const SizedBox(width: 8),
                    Text(
                          _tr('Đăng ký làm Shipper', 'Register as shipper'),
                          style: const TextStyle(
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
        _tr('Đã có tài khoản? ', 'Already have an account? '),
        style: TextStyle(color: Colors.grey[600]),
      ),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text(
          _tr('Đăng nhập ngay', 'Log in now'),
          style: const TextStyle(
            color: ShipperTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return _tr('Vui lòng nhập họ và tên', 'Please enter full name');
    }
    if (value.trim().length < 2) {
      return _tr('Họ tên phải có ít nhất 2 ký tự', 'Name must be at least 2 characters');
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return _tr('Vui lòng nhập số điện thoại', 'Please enter phone number');
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
      return _tr('Vui lòng nhập mật khẩu', 'Please enter password');
    }
    if (value.length < 6) {
      return _tr('Mật khẩu phải có ít nhất 6 ký tự', 'Password must be at least 6 characters');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return _tr('Vui lòng xác nhận mật khẩu', 'Please confirm password');
    }
    if (value != _passwordController.text) {
      return _tr('Mật khẩu xác nhận không khớp', 'Password confirmation does not match');
    }
    return null;
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final provinces = await _provinceApi.getProvincesV2();
      if (!mounted) return;

      setState(() {
        _provinces = provinces;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = _tr(
          'Không thể tải danh sách tỉnh/phường',
          'Unable to load province/ward list',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _onProvinceChanged(LocationItem? province) async {
    setState(() {
      _selectedProvince = province;
      _selectedWard = null;
      _wards = [];
      _locationError = null;
    });

    if (province == null) return;

    try {
      final wards = await _provinceApi.getWardsByProvince(province.code);
      if (!mounted) return;
      setState(() {
        _wards = wards;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = _tr('Không thể tải danh sách phường', 'Unable to load ward list');
      });
    }
  }

  void _onWardChanged(LocationItem? ward) {
    setState(() {
      _selectedWard = ward;
    });
  }

  Widget _buildLocationDropdown({
    required String label,
    required List<LocationItem> items,
    required ValueChanged<LocationItem?>? onChanged,
    LocationItem? value,
    String? hintText,
  }) {
    return DropdownButtonFormField<LocationItem>(
      initialValue: value,
      items: items
          .map(
            (item) => DropdownMenuItem<LocationItem>(
              value: item,
              child: Text(item.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
    );
  }

  String? _buildAddressPayload() {
    final street = _streetController.text.trim();
    final hasStreet = street.isNotEmpty;
    final hasProvince = _selectedProvince != null;
    final hasWard = _selectedWard != null;

    if (!hasStreet && !hasProvince && !hasWard) {
      return null;
    }

    if (hasStreet && hasProvince && hasWard) {
      return '$street, ${_selectedWard!.name}, ${_selectedProvince!.name}';
    }

    return '';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final address = _buildAddressPayload();
    if (address == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Vui lòng nhập đủ đường, phường/xã và tỉnh/thành phố hoặc để trống toàn bộ địa chỉ',
              'Please provide street, ward/commune and province/city or leave the entire address empty',
            ),
          ),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('Vui lòng đồng ý với điều khoản sử dụng', 'Please agree to the terms of use'),
          ),
        ),
      );
      return;
    }

    _authBloc.add(
      ShipperRegisterRequested(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        address: address,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
