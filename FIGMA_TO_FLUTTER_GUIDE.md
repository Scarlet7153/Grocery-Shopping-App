# 🎨 HƯỚNG DẪN CHUYỂN ĐỔI FIGMA SANG FLUTTER

## 📋 Tổng Quan

Guide này hướng dẫn cách chuyển đổi thiết kế Figma thành Flutter code cho dự án App Đi Chợ Hộ.

**Admin Figma Link**: https://www.figma.com/design/llpTg3SIY7Tv2WVoUkHncl/App-%C4%91i-ch%E1%BB%A3-h%E1%BB%99?node-id=22-261&p=f&t=nJ9Z0KU3qFhCHBzk-0

**Customer Figma Link**: https://www.figma.com/design/llpTg3SIY7Tv2WVoUkHncl/App-%C4%91i-ch%E1%BB%A3-h%E1%BB%99?node-id=0-1&p=f&t=nJ9Z0KU3qFhCHBzk-0

**Store Figma Link**: https://www.figma.com/design/llpTg3SIY7Tv2WVoUkHncl/App-%C4%91i-ch%E1%BB%A3-h%E1%BB%99?node-id=22-157&p=f&t=nJ9Z0KU3qFhCHBzk-0

**Shipper Figma Link**: https://www.figma.com/design/llpTg3SIY7Tv2WVoUkHncl/App-%C4%91i-ch%E1%BB%A3-h%E1%BB%99?node-id=15-57&p=f&t=nJ9Z0KU3qFhCHBzk-0

## 🎯 Phân Chia Platform

### 📱 **Mobile App (Flutter)**
- **Customer** - Khách hàng
- **Store Owner** - Chủ cửa hàng  
- **Shipper** - Người giao hàng

### 💻 **Web Admin (Flutter Web)**
- **Admin** - Quản trị viên

---

## 🛠️ QUY TRÌNH CHUYỂN ĐỔI

### Bước 1: Phân Tích Figma

#### 📐 **Extract Design System**
```bash
# Các thông số cần lấy từ Figma:
1. Colors (Màu sắc)
   - Primary colors
   - Secondary colors
   - Text colors
   - Background colors
   - Error/Success/Warning colors

2. Typography (Font chữ)
   - Font families
   - Font sizes
   - Font weights
   - Line heights

3. Spacing (Khoảng cách)
   - Margins
   - Paddings
   - Border radius
   - Elevations/Shadows

4. Components (Thành phần)
   - Buttons
   - Input fields
   - Cards
   - Icons
   - Images
```

#### 🖼️ **Export Assets**
1. **Icons**: Export as SVG (24x24, 32x32)
2. **Images**: Export as PNG/JPG (1x, 2x, 3x)
3. **Logos**: Export as SVG và PNG

### Bước 2: Setup Design System trong Flutter

#### 📂 **Cấu trúc thư mục**
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Màu sắc từ Figma
│   │   ├── app_text_styles.dart # Typography từ Figma
│   │   ├── app_theme.dart       # Theme tổng thể
│   │   └── app_dimensions.dart  # Spacing, sizes từ Figma
│   └── constants/
│       ├── app_assets.dart      # Đường dẫn assets
│       └── app_strings.dart     # Text strings
├── shared/
│   └── widgets/
│       ├── buttons/             # Custom buttons từ Figma
│       ├── inputs/              # Input fields từ Figma
│       └── cards/               # Card components từ Figma
└── features/
    └── auth/
        └── presentation/
            └── screens/         # Login/Register screens
```

### Bước 3: Implement Design System

#### 🎨 **Colors (app_colors.dart)**
```dart
class AppColors {
  // Primary Colors từ Figma
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  
  // Secondary Colors
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color accent = Color(0xFF2196F3);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Role Colors (cho Customer/Store/Shipper)
  static const Color customerColor = Color(0xFF2196F3);   // Blue
  static const Color storeColor = Color(0xFF4CAF50);      // Green  
  static const Color shipperColor = Color(0xFFFF9800);    // Orange
  static const Color adminColor = Color(0xFF9C27B0);      // Purple
}
```

#### ✏️ **Typography (app_text_styles.dart)**
```dart
class AppTextStyles {
  // Heading Styles từ Figma
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
    height: 1.2,
  );
  
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
    height: 1.2,
  );
  
  // Input Styles
  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
}
```

#### 📏 **Dimensions (app_dimensions.dart)**
```dart
class AppDimensions {
  // Spacing từ Figma
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  
  // Border Radius từ Figma
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusRound = 24.0;
  
  // Button Sizes từ Figma
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;
  
  // Input Field Sizes
  static const double inputHeight = 48.0;
  static const double inputMinHeight = 44.0;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Card/Container Sizes
  static const double cardElevation = 2.0;
  static const double modalElevation = 8.0;
}
```

### Bước 4: Tạo Custom Widgets từ Figma

#### 🔘 **Custom Button (từ Figma design)**
```dart
// lib/shared/widgets/buttons/custom_button.dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final Color? customColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.customColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getButtonHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          elevation: _getElevation(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: _getBorderSide(),
          ),
        ),
        child: isLoading ? _buildLoadingWidget() : _buildContent(),
      ),
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightSmall;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightMedium;
      case ButtonSize.large:
        return AppDimensions.buttonHeightLarge;
    }
  }

  Color _getBackgroundColor() {
    if (customColor != null) return customColor!;
    
    switch (type) {
      case ButtonType.primary:
        return AppColors.primaryGreen;
      case ButtonType.secondary:
        return AppColors.secondaryOrange;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.ghost:
        return Colors.transparent;
    }
  }

  // ... các method khác
}

enum ButtonType { primary, secondary, outline, ghost }
enum ButtonSize { small, medium, large }
```

#### 📝 **Custom Input Field (từ Figma design)**
```dart
// lib/shared/widgets/inputs/custom_input_field.dart
class CustomInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.onChanged,
    this.validator,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) _buildLabel(),
        const SizedBox(height: AppDimensions.spacing8),
        _buildTextField(),
        if (widget.errorText != null) _buildErrorText(),
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label!,
        style: AppTextStyles.inputLabel,
        children: widget.isRequired ? [
          TextSpan(
            text: ' *',
            style: AppTextStyles.inputLabel.copyWith(
              color: AppColors.error,
            ),
          ),
        ] : null,
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: widget.errorText != null 
              ? AppColors.error 
              : AppColors.textHint.withOpacity(0.3),
        ),
        color: AppColors.surface,
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        style: AppTextStyles.inputText,
        onChanged: widget.onChanged,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: widget.prefixIcon != null 
              ? Icon(widget.prefixIcon, color: AppColors.textHint) 
              : null,
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing12,
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textHint,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    return widget.suffixWidget;
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacing4),
      child: Text(
        widget.errorText!,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
    );
  }
}
```

### Bước 5: Implement Login/Register Screens

#### 🔐 **Login Screen Template**
```dart
// lib/features/auth/presentation/screens/login_screen.dart
class LoginScreen extends StatefulWidget {
  final UserRole userRole; // Customer, Store, Shipper

  const LoginScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getRoleBackgroundColor(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.spacing40),
                _buildLoginForm(),
                const SizedBox(height: AppDimensions.spacing24),
                _buildLoginButton(),
                const SizedBox(height: AppDimensions.spacing16),
                _buildRegisterLink(),
                _buildForgotPasswordLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo/Icon theo role từ Figma
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            color: _getRolePrimaryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Icon(
            _getRoleIcon(),
            size: AppDimensions.iconXLarge,
            color: _getRolePrimaryColor(),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing24),
        Text(
          'Đăng nhập ${_getRoleDisplayName()}',
          style: AppTextStyles.heading1.copyWith(
            color: _getRolePrimaryColor(),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          'Chào mừng trở lại! Vui lòng nhập thông tin đăng nhập.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        CustomInputField(
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone,
          isRequired: true,
          validator: _validatePhone,
        ),
        const SizedBox(height: AppDimensions.spacing20),
        CustomInputField(
          label: 'Mật khẩu',
          hint: 'Nhập mật khẩu',
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icons.lock,
          isRequired: true,
          validator: _validatePassword,
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
        customColor: _getRolePrimaryColor(),
      ),
    );
  }

  // Helper methods để lấy màu sắc và icon theo role
  Color _getRolePrimaryColor() {
    switch (widget.userRole) {
      case UserRole.customer:
        return AppColors.customerColor;
      case UserRole.store:
        return AppColors.storeColor;
      case UserRole.shipper:
        return AppColors.shipperColor;
      case UserRole.admin:
        return AppColors.adminColor;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.userRole) {
      case UserRole.customer:
        return Icons.shopping_cart;
      case UserRole.store:
        return Icons.store;
      case UserRole.shipper:
        return Icons.delivery_dining;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleDisplayName() {
    switch (widget.userRole) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.store:
        return 'Chủ cửa hàng';
      case UserRole.shipper:
        return 'Shipper';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  // Validation methods
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (value.length != 10) {
      return 'Số điện thoại phải có 10 chữ số';
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

    try {
      // TODO: Implement login logic với API
      await Future.delayed(const Duration(seconds: 2)); // Mock delay
      
      // Navigate to appropriate home screen based on role
      if (mounted) {
        _navigateToHome();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    // TODO: Navigate based on role
    switch (widget.userRole) {
      case UserRole.customer:
        // Navigate to customer home
        break;
      case UserRole.store:
        // Navigate to store dashboard
        break;
      case UserRole.shipper:
        // Navigate to shipper dashboard
        break;
      case UserRole.admin:
        // Navigate to admin dashboard
        break;
    }
  }
}
```

---

## 🚀 THỰC HIỆN TỪNG BƯỚC

### Bước 1: Chuẩn Bị Assets
```bash
# Tạo thư mục assets
mkdir -p assets/images/auth
mkdir -p assets/icons
mkdir -p assets/fonts

# Export từ Figma:
# - Logo cho từng role
# - Background images
# - Icons
# - Any custom fonts
```

### Bước 2: Setup Design System
1. Tạo `app_colors.dart` với màu sắc từ Figma
2. Tạo `app_text_styles.dart` với typography
3. Tạo `app_dimensions.dart` với spacing
4. Update `app_theme.dart` để sử dụng design system mới

### Bước 3: Tạo Custom Widgets
1. `CustomButton` theo design Figma
2. `CustomInputField` theo design Figma  
3. `RoleSelectionCard` cho chọn role
4. `AuthHeader` widget tái sử dụng

### Bước 4: Implement Auth Screens
1. `RoleSelectionScreen` - Chọn vai trò
2. `LoginScreen` cho từng role
3. `RegisterScreen` cho từng role
4. `ForgotPasswordScreen`

### Bước 5: Setup Navigation
1. Setup GoRouter với auth routes
2. Implement role-based navigation
3. Add route guards

---

## 🔍 TIPS & BEST PRACTICES

### 📐 Measuring từ Figma
1. **Spacing**: Dùng ruler tool trong Figma
2. **Font sizes**: Check text properties panel
3. **Colors**: Copy exact hex codes
4. **Border radius**: Check corner radius properties
5. **Shadows**: Export shadow CSS và convert sang Flutter

### 🎨 Color Naming Convention
```dart
// Theo role
static const Color customerPrimary = Color(0xFF2196F3);
static const Color customerSecondary = Color(0xFF64B5F6);

// Theo usage
static const Color backgroundLight = Color(0xFFFAFAFA);
static const Color backgroundDark = Color(0xFF303030);
```

### 📱 Responsive Design
```dart
// Sử dụng MediaQuery cho responsive
final screenWidth = MediaQuery.of(context).size.width;
final isTablet = screenWidth > 768;

// Adjust sizes based on screen
final buttonHeight = isTablet ? 56.0 : 48.0;
```

---

## 🎯 CHECKLIST IMPLEMENTATION

### Phase 1: Design System ✅
- [ ] Extract colors từ Figma
- [ ] Extract typography từ Figma  
- [ ] Extract spacing/dimensions từ Figma
- [ ] Setup app_colors.dart
- [ ] Setup app_text_styles.dart
- [ ] Setup app_dimensions.dart
- [ ] Update app_theme.dart

### Phase 2: Custom Widgets
- [ ] CustomButton theo Figma design
- [ ] CustomInputField theo Figma design
- [ ] Role selection components
- [ ] Auth header components
- [ ] Loading states
- [ ] Error states

### Phase 3: Auth Screens
- [ ] RoleSelectionScreen
- [ ] LoginScreen (Customer)
- [ ] LoginScreen (Store)  
- [ ] LoginScreen (Shipper)
- [ ] LoginScreen (Admin) - Web version
- [ ] RegisterScreen (Customer)
- [ ] RegisterScreen (Store)
- [ ] RegisterScreen (Shipper)
- [ ] ForgotPasswordScreen

### Phase 4: Navigation & State
- [ ] Setup GoRouter với auth routes
- [ ] Implement AuthBloc
- [ ] Role-based navigation
- [ ] Route guards
- [ ] Deep linking support

---

**Happy Designing! 🎨✨**

---

## ✅ TÌNH TRẠNG HIỆN TẠI (Updated)

### Đã Hoàn Thành:

#### 🎨 **Design System** ✅
- [x] `app_colors.dart` - Màu sắc theo role (Customer: Blue, Store: Green, Shipper: Orange, Admin: Purple)
- [x] `app_text_styles.dart` - Typography system với Vietnamese font support
- [x] `app_dimensions.dart` - Spacing, sizes, và breakpoints
- [x] `UserRole` enum với colors, icons, và permissions
- [x] `RoleColorHelper` utility class

#### 🧩 **Custom Widgets** ✅  
- [x] `CustomButton` - Hỗ trợ 5 loại button với animation và role colors
- [x] `CustomTextField` - Input fields với validation và role theming  
- [x] `RoleSelectionCard` - Card chọn role với animation
- [x] `LoadingWidget` - Loading states

#### 📱 **Auth Screens** ✅
- [x] `RoleSelectionScreen` - Chọn Customer/Store/Shipper với animation
- [x] `LoginScreen` - Login theo từng role với validation
- [x] `RegisterScreen` - Register theo role với form đầy đủ

### Đã Setup:
```
mobile_app/
├── lib/
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart       ✅ Role-based colors
│   │   │   ├── app_text_styles.dart  ✅ Typography system
│   │   │   └── app_dimensions.dart   ✅ Spacing & sizes
│   │   ├── enums/
│   │   │   └── user_role.dart        ✅ UserRole enum
│   │   └── utils/
│   │       └── role_color_helper.dart ✅ Color utilities
│   ├── features/
│   │   └── auth/
│   │       └── presentation/
│   │           ├── screens/
│   │           │   ├── role_selection_screen.dart  ✅
│   │           │   ├── login_screen.dart           ✅  
│   │           │   └── register_screen.dart        ✅
│   │           └── widgets/
│   │               └── role_selection_card.dart    ✅
│   └── shared/
│       └── widgets/
│           ├── buttons/
│           │   ├── custom_button.dart    ✅
│           │   └── buttons.dart          ✅ Export file
│           └── custom_text_field.dart    ✅
```

### Sẵn sàng sử dụng:
1. **Role Selection** - Chọn Customer/Store/Shipper
2. **Login Form** - Đăng nhập theo role với validation
3. **Register Form** - Đăng ký với thông tin đầy đủ
4. **Design System** - Consistent theming across roles

### Tiếp theo cần làm:
1. **Navigation Setup** - GoRouter với route guards
2. **API Integration** - Connect với backend  
3. **Home Screens** - Tạo dashboard cho từng role
4. **State Management** - Setup BLoC pattern

### Hướng dẫn chạy thử:
```bash
cd mobile_app
flutter pub get
flutter run -d chrome  # Hoặc device bất kỳ
```

Navigat flow: `RoleSelectionScreen` → `LoginScreen` → `RegisterScreen`
