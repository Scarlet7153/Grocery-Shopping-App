import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/province_api.dart';
import '../../services/province_api_v2.dart';
import '../../../../core/theme/customer_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../bloc/customer_auth_bloc.dart';
import '../../utils/customer_l10n.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final _provinceApi = ProvinceApiV2();
  List<LocationItem> _provinces = [];
  List<LocationItem> _districts = [];
  List<LocationItem> _wards = [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedDistrict;
  LocationItem? _selectedWard;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
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
    if (!mounted) return;
    if (districts.isEmpty) {
      final wards = await _provinceApi.getWardsByProvince(item.code);
      if (!mounted) return;
      setState(() {
        _districts = [];
        _wards = wards;
      });
    } else {
      setState(() {
        _districts = districts;
        _wards = [];
      });
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
    final parts = <String>[
      if (_selectedWard?.name.isNotEmpty == true) _selectedWard!.name,
      if (_districts.isNotEmpty && _selectedDistrict?.name.isNotEmpty == true)
        _selectedDistrict!.name,
      if (_selectedProvince?.name.isNotEmpty == true) _selectedProvince!.name,
    ];
    _addressController.text = parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocListener<CustomerAuthBloc, CustomerAuthState>(
      listener: (context, state) {
        if (state is CustomerAuthLoading) {
          setState(() => _isLoading = true);
        }

        if (state is CustomerAuthSuccess) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(vi: 'Đăng ký thành công!', en: 'Sign up successful!')),
              backgroundColor: CustomerTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
        }

        if (state is CustomerAuthFailure) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_localizedAuthError(state.message)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(context.tr(vi: 'Đăng ký tài khoản', en: 'Create account')),
          backgroundColor: scheme.surface,
          elevation: 0,
          foregroundColor: scheme.onSurface,
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
                  _buildContactInfo(),
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
          Icons.person_add,
          size: 32,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Create a new account',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(
          vi: 'Đăng ký để mua sắm và giao hàng tận nhà',
          en: 'Sign up to shop and get home delivery',
        ),
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    ],
  );

  Widget _buildPersonalInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Personal information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: context.tr(vi: 'Họ và tên *', en: 'Full name *'),
        hint: context.tr(vi: 'Nhập họ và tên đầy đủ', en: 'Enter your full name'),
        controller: _nameController,
        keyboardType: TextInputType.name,
        prefixIcon: Icons.person,
        validator: _validateName,
        focusColor: CustomerTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: context.tr(vi: 'Số điện thoại *', en: 'Phone number *'),
        hint: context.tr(
          vi: 'Nhập số điện thoại (vd: 0352773474)',
          en: 'Enter phone number (e.g. 0352773474)',
        ),
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone,
        validator: _validatePhone,
        focusColor: CustomerTheme.primaryColor,
      ),
    ],
  );

  Widget _buildContactInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Contact information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      _buildLocationDropdown(
        label: context.tr(vi: 'Tỉnh/Thành phố *', en: 'Province/City *'),
        value: _selectedProvince,
        items: _provinces,
        onChanged: _isLoadingLocation ? null : _onProvinceChanged,
        prefixIcon: Icons.location_city_outlined,
      ),
      if (_districts.isNotEmpty) ...[
        const SizedBox(height: 16),
        _buildLocationDropdown(
          label: context.tr(vi: 'Quận/Huyện *', en: 'District *'),
          value: _selectedDistrict,
          items: _districts,
          onChanged: _selectedProvince == null ? null : _onDistrictChanged,
          prefixIcon: Icons.map_outlined,
        ),
      ],
      const SizedBox(height: 16),
      _buildLocationDropdown(
        label: context.tr(vi: 'Phường/Xã *', en: 'Ward/Commune *'),
        value: _selectedWard,
        items: _wards,
        onChanged:
            (_districts.isNotEmpty ? (_selectedDistrict == null) : (_selectedProvince == null))
                ? null
                : _onWardChanged,
        prefixIcon: Icons.place_outlined,
        validator: (value) {
          if (value == null) {
            return context.tr(vi: 'Vui lòng chọn địa chỉ', en: 'Please select an address');
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: context.tr(vi: 'Tên đường *', en: 'Street *'),
        hint: context.tr(vi: 'Nhập tên đường', en: 'Enter street name'),
        controller: _streetController,
        keyboardType: TextInputType.streetAddress,
        prefixIcon: Icons.home_repair_service,
        validator: _validateStreet,
        focusColor: CustomerTheme.primaryColor,
      ),
    ],
  );

  Widget _buildSecurityInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Security',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: context.tr(vi: 'Mật khẩu *', en: 'Password *'),
        hint: context.tr(
          vi: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
          en: 'Enter password (at least 6 characters)',
        ),
        controller: _passwordController,
        isPassword: true,
        prefixIcon: Icons.lock,
        validator: _validatePassword,
        focusColor: CustomerTheme.primaryColor,
      ),
    ],
  );

  Widget _buildTermsCheckbox() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Checkbox(
        value: _agreeToTerms,
        onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
        activeColor: CustomerTheme.primaryColor,
      ),
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              children: [
                TextSpan(text: context.tr(vi: 'Tôi đồng ý với ', en: 'I agree with ')),
                TextSpan(
                  text: 'Terms of service',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: context.tr(vi: ' và ', en: ' and ')),
                TextSpan(
                  text: 'Privacy policy',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: context.tr(vi: ' của ứng dụng này.', en: ' of this app.')),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildRegisterButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: (_isLoading || !_agreeToTerms) ? null : _handleRegister,
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomerTheme.primaryColor,
        foregroundColor: Colors.white,
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
          : Text(
              context.tr(vi: 'Đăng ký', en: 'Sign up'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    ),
  );

  Widget _buildLoginLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        context.tr(vi: 'Đã có tài khoản? ', en: 'Already have an account? '),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text(
          context.tr(vi: 'Đăng nhập ngay', en: 'Sign in now'),
          style: TextStyle(
            color: CustomerTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr(vi: 'Vui lòng nhập họ và tên', en: 'Please enter full name');
    }
    if (value.trim().length < 2) {
      return context.tr(vi: 'Họ tên phải có ít nhất 2 ký tự', en: 'Name must be at least 2 characters');
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr(vi: 'Vui lòng nhập số điện thoại', en: 'Please enter phone number');
    }
    if (value.length != 10 || !RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
      return context.tr(
        vi: 'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)',
        en: 'Invalid phone number (10 digits, starts with 0)',
      );
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null) {
      return context.tr(vi: 'Vui lòng chọn đầy đủ địa chỉ', en: 'Please complete address selection');
    }
    return null;
  }

  String? _validateStreet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr(vi: 'Vui lòng nhập tên đường', en: 'Please enter street name');
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.tr(vi: 'Vui lòng nhập mật khẩu', en: 'Please enter password');
    }
    if (value.length < 6) {
      return context.tr(vi: 'Mật khẩu phải có ít nhất 6 ký tự', en: 'Password must be at least 6 characters');
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(
          vi: 'Vui lòng đồng ý với điều khoản sử dụng',
          en: 'Please accept the terms of service',
        ))),
      );
      return;
    }

    final fullAddress = [
      _streetController.text.trim(),
      _addressController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    context.read<CustomerAuthBloc>().add(
      CustomerRegisterEvent(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        address: fullAddress,
      ),
    );
  }

  String _localizedAuthError(String message) {
    if (message.contains('Đăng ký thất bại')) {
      return context.tr(vi: 'Đăng ký thất bại', en: 'Sign up failed');
    }
    if (message.contains('Không thể kết nối đến máy chủ')) {
      return context.tr(vi: 'Không thể kết nối đến máy chủ', en: 'Cannot connect to server');
    }
    if (message.contains('Dữ liệu không hợp lệ')) {
      return context.tr(vi: 'Dữ liệu không hợp lệ', en: 'Invalid data');
    }
    if (message.contains('Số điện thoại không hợp lệ') ||
        message.contains('Invalid phone number')) {
      return context.tr(
        vi: 'Số điện thoại không hợp lệ',
        en: 'Invalid phone number',
      );
    }
    return message;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      validator: validator ?? (_) => _validateAddress(null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
