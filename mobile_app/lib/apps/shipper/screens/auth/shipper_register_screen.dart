import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/shared/widgets/custom_text_field.dart';
import 'package:grocery_shopping_app/apps/shipper/bloc/shipper_auth_bloc.dart';

class ShipperRegisterScreen extends StatefulWidget {
  const ShipperRegisterScreen({super.key});

  @override
  State<ShipperRegisterScreen> createState() => _ShipperRegisterScreenState();
}

class _ShipperRegisterScreenState extends State<ShipperRegisterScreen> {
  final _formKey = GlobalKey<FormState>();  // ✅ Fixed: FormState instead of FormKey
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _bankAccountController = TextEditingController();
  
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String _selectedVehicleType = 'Xe máy';

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
              _buildContactInfo(),
              const SizedBox(height: 24),
              _buildVehicleInfo(),
              const SizedBox(height: 24),
              _buildDocumentInfo(),
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
      // Shipper delivery icon
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
        label: 'CMND/CCCD *',
        hint: 'Nhập số CMND hoặc CCCD',
        controller: _idNumberController,
        keyboardType: TextInputType.number,
        prefixIcon: Icons.credit_card,
        validator: _validateIdNumber,
        focusColor: ShipperTheme.primaryColor,
      ),
    ],
  );

  Widget _buildContactInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Thông tin liên hệ', Icons.contact_phone),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Email',
        hint: 'Nhập địa chỉ email (tùy chọn)',
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        prefixIcon: Icons.email,
        validator: _validateEmail,
        focusColor: ShipperTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Địa chỉ thường trú *',
        hint: 'Nhập địa chỉ thường trú',
        controller: _addressController,
        prefixIcon: Icons.location_on,
        validator: _validateAddress,
        focusColor: ShipperTheme.primaryColor,
        maxLines: 2,
      ),
    ],
  );

  Widget _buildVehicleInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Thông tin phương tiện', Icons.motorcycle),
      const SizedBox(height: 16),
      
      // ✅ Fixed: Vehicle type dropdown with proper initialValue
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedVehicleType,  // ✅ Fixed: use initialValue instead of value
          decoration: const InputDecoration(
            labelText: 'Loại phương tiện *',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.motorcycle),
          ),
          items: ['Xe máy', 'Xe đạp điện', 'Ô tô', 'Xe tải nhỏ']
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedVehicleType = value!);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn loại phương tiện';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Biển số xe *',
        hint: 'Nhập biển số phương tiện',
        controller: _vehiclePlateController,
        prefixIcon: Icons.confirmation_number,
        validator: _validateVehiclePlate,
        focusColor: ShipperTheme.primaryColor,
      ),
    ],
  );

  Widget _buildDocumentInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Thông tin ngân hàng', Icons.account_balance),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Số tài khoản ngân hàng *',
        hint: 'Nhập số tài khoản để nhận thanh toán',
        controller: _bankAccountController,
        keyboardType: TextInputType.number,
        prefixIcon: Icons.account_balance_wallet,
        validator: _validateBankAccount,
        focusColor: ShipperTheme.primaryColor,
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
              children: const [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản dành cho Shipper',
                  style: TextStyle(
                    color: Color(0xFFFF9800),  // ShipperTheme.primaryColor
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: TextStyle(
                    color: Color(0xFFFF9800),  // ShipperTheme.primaryColor
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
              content: Text('Đăng ký thành công! Chào mừng bạn trở thành Shipper'),
              backgroundColor: ShipperTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
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

  // Validation methods
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

  String? _validateIdNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số CMND/CCCD';
    }
    if (value.length < 9 || value.length > 12) {
      return 'Số CMND/CCCD không hợp lệ';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Địa chỉ email không hợp lệ';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập địa chỉ';
    }
    if (value.trim().length < 5) {
      return 'Địa chỉ phải có ít nhất 5 ký tự';
    }
    return null;
  }

  String? _validateVehiclePlate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập biển số xe';
    }
    if (value.trim().length < 5) {
      return 'Biển số xe không hợp lệ';
    }
    return null;
  }

  String? _validateBankAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tài khoản ngân hàng';
    }
    if (value.length < 6) {
      return 'Số tài khoản ngân hàng không hợp lệ';
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

    // collect data
    final info = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'vehicleType': _selectedVehicleType,
      'vehiclePlate': _vehiclePlateController.text.trim(),
      'idNumber': _idNumberController.text.trim(),
      'bankAccount': _bankAccountController.text.trim(),
      'password': _passwordController.text,
    };

    _authBloc.add(ShipperRegisterRequested(registrationInfo: info));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    _idNumberController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }
}