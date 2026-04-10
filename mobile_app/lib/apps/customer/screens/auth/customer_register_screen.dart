import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/province_api.dart';
import '../../../../core/theme/customer_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../bloc/customer_auth_bloc.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final _provinceApi = ProvinceApi();
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
    ].where((e) => e != null && e.isNotEmpty).map((e) => e!).toList();
    _addressController.text = parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerAuthBloc, CustomerAuthState>(
      listener: (context, state) {
        if (state is CustomerAuthLoading) {
          setState(() => _isLoading = true);
        }

        if (state is CustomerAuthSuccess) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: CustomerTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
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
        appBar: AppBar(
          title: const Text('Đăng ký tài khoản'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: CustomerTheme.primaryColor,
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
        'Tạo tài khoản mới',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Đăng ký để mua sắm và giao hàng tận nhà',
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
      ),
    ],
  );

  Widget _buildPersonalInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Thông tin cá nhân',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Họ và tên *',
        hint: 'Nhập họ và tên đầy đủ',
        controller: _nameController,
        keyboardType: TextInputType.name,
        prefixIcon: Icons.person,
        validator: _validateName,
        focusColor: CustomerTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Số điện thoại *',
        hint: 'Nhập số điện thoại (vd: 0352773474)',
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
        'Thông tin liên hệ',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      _buildLocationDropdown(
        label: 'Tỉnh/Thành phố *',
        value: _selectedProvince,
        items: _provinces,
        onChanged: _isLoadingLocation ? null : _onProvinceChanged,
        prefixIcon: Icons.location_city_outlined,
      ),
      const SizedBox(height: 16),
      _buildLocationDropdown(
        label: 'Quận/Huyện *',
        value: _selectedDistrict,
        items: _districts,
        onChanged: _selectedProvince == null ? null : _onDistrictChanged,
        prefixIcon: Icons.map_outlined,
      ),
      const SizedBox(height: 16),
      _buildLocationDropdown(
        label: 'Phường/Xã *',
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

  Widget _buildSecurityInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Bảo mật',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CustomerTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Mật khẩu *',
        hint: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
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
                color: Colors.grey[700],
                height: 1.4,
              ),
              children: const [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
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
          : const Text(
              'Đăng ký',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    ),
  );

  Widget _buildLoginLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Đã có tài khoản? ', style: TextStyle(color: Colors.grey[600])),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text(
          'Đăng nhập ngay',
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

  String? _validateAddress(String? value) {
    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null) {
      return 'Vui lòng chọn đầy đủ địa chỉ';
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản sử dụng')),
      );
      return;
    }

    context.read<CustomerAuthBloc>().add(
      CustomerRegisterEvent(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        address: _addressController.text,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
