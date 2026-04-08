import 'package:flutter/material.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class StoreRegisterScreen extends StatefulWidget {
  const StoreRegisterScreen({super.key});

  @override
  State<StoreRegisterScreen> createState() => _StoreRegisterScreenState();
}

class _StoreRegisterScreenState extends State<StoreRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: StoreTheme.backgroundColor,
    appBar: AppBar(
      title: const Text('Đăng ký cửa hàng'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: StoreTheme.primaryColor,
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
              _buildStoreInfo(),
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
      const Text(
        'Đăng ký cửa hàng',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: StoreTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tạo tài khoản để bán hàng trên nền tảng của chúng tôi',
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
      ),
    ],
  );

  Widget _buildPersonalInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Thông tin chủ cửa hàng',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: StoreTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Họ và tên chủ cửa hàng *',
        hint: 'Nhập họ và tên đầy đủ',
        controller: _ownerNameController,
        keyboardType: TextInputType.name,
        prefixIcon: Icons.person,
        validator: _validateName,
        focusColor: StoreTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Số điện thoại *',
        hint: 'Nhập số điện thoại',
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone,
        validator: _validatePhone,
        focusColor: StoreTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Email',
        hint: 'Nhập địa chỉ email (tùy chọn)',
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        prefixIcon: Icons.email,
        validator: _validateEmail,
        focusColor: StoreTheme.primaryColor,
      ),
    ],
  );

  Widget _buildStoreInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Thông tin cửa hàng',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: StoreTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Tên cửa hàng *',
        hint: 'Nhập tên cửa hàng',
        controller: _storeNameController,
        prefixIcon: Icons.store,
        validator: _validateStoreName,
        focusColor: StoreTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Địa chỉ cửa hàng *',
        hint: 'Nhập địa chỉ cửa hàng',
        controller: _storeAddressController,
        prefixIcon: Icons.location_on,
        validator: _validateStoreAddress,
        focusColor: StoreTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Số giấy phép kinh doanh *',
        hint: 'Nhập số giấy phép kinh doanh',
        controller: _businessLicenseController,
        prefixIcon: Icons.business,
        validator: _validateBusinessLicense,
        focusColor: StoreTheme.primaryColor,
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
          color: StoreTheme.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        label: 'Mật khẩu *',
        hint: 'Nhập mật khẩu (tối thiểu 8 ký tự)',
        controller: _passwordController,
        isPassword: true,
        prefixIcon: Icons.lock,
        validator: _validatePassword,
        focusColor: StoreTheme.primaryColor,
      ),
      const SizedBox(height: 20),
      CustomTextField(
        label: 'Xác nhận mật khẩu *',
        hint: 'Nhập lại mật khẩu',
        controller: _confirmPasswordController,
        isPassword: true,
        prefixIcon: Icons.lock_outline,
        validator: _validateConfirmPassword,
        focusColor: StoreTheme.primaryColor,
      ),
    ],
  );

  Widget _buildTermsCheckbox() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Checkbox(
        value: _agreeToTerms,
        onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
        activeColor: StoreTheme.primaryColor,
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
                // Fixed - Added const to children array
                TextSpan(text: 'Tôi đồng ý với '), // Fixed - Added const
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: TextStyle(
                    color: Color(
                      0xFF4CAF50,
                    ), // Fixed - Use hardcoded color instead of StoreTheme.primaryColor
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ), // Fixed - Added const
                TextSpan(text: ' và '), // Fixed - Added const
                TextSpan(
                  text: 'Chính sách bán hàng',
                  style: TextStyle(
                    color: Color(
                      0xFF4CAF50,
                    ), // Fixed - Use hardcoded color instead of StoreTheme.primaryColor
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ), // Fixed - Added const
                TextSpan(text: ' của ứng dụng.'), // Fixed - Added const
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
        backgroundColor: StoreTheme.primaryColor,
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
              'Đăng ký cửa hàng',
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
            color: StoreTheme.primaryColor,
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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Địa chỉ email không hợp lệ';
    }
    return null;
  }

  String? _validateStoreName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên cửa hàng';
    }
    if (value.trim().length < 2) {
      return 'Tên cửa hàng phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validateStoreAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập địa chỉ cửa hàng';
    }
    if (value.trim().length < 5) {
      return 'Địa chỉ phải có ít nhất 5 ký tự';
    }
    return null;
  }

  String? _validateBusinessLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số giấy phép kinh doanh';
    }
    if (value.trim().length < 8) {
      return 'Số giấy phép kinh doanh không hợp lệ';
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
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 số';
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

    setState(() => _isLoading = true);

    try {
      // Mock store registration API call
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký cửa hàng thành công! Vui lòng chờ duyệt.'),
            backgroundColor: StoreTheme.primaryColor,
          ),
        );
        Navigator.pop(context); // Back to login
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _businessLicenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
