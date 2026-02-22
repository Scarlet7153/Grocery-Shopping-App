# 🚀 HƯỚNG DẪN CHI TIẾT PHASE 1 - PROJECT SETUP

## 📋 Tổng quan Phase 1
Phase 1 bao gồm 3 nhiệm vụ chính:
1. **Project Initialization** - Tạo project và cấu trúc thư mục
2. **Core Dependencies** - Cài đặt và cấu hình packages
3. **Base Widgets** - Tạo các widgets cơ bản

---

## 🎯 BƯỚC 1: PROJECT INITIALIZATION

### 1.1 Tạo Flutter Project
```bash
# Từ thư mục gốc Grocery-Shopping-App (nơi có BACKEND_PLAN.md)
cd d:\DoAnChuyenNganh\Grocery-Shopping-App

# Tạo Flutter project trong thư mục con
flutter create mobile_app
cd mobile_app

# Kiểm tra Flutter version (cần >=3.10.0)
flutter --version
flutter doctor
```

**⚠️ LƯU Ý:** Tạo Flutter project **TRONG** thư mục project hiện tại, không tạo project riêng biệt!

### 1.2 Xóa files không cần thiết
**Cho PowerShell (Windows):**
```powershell
# Xóa main.dart (nếu tồn tại)
if (Test-Path "lib/main.dart") { Remove-Item "lib/main.dart" }

# Xóa thư mục test (nếu tồn tại)  
if (Test-Path "test") { Remove-Item -Recurse -Force "test" }
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
rm lib/main.dart
rm -rf test/
```

### 1.3 Tạo cấu trúc thư mục

**⚠️ QUAN TRỌNG: Chạy các lệnh này TRONG thư mục `mobile_app/` (đã cd vào rồi)**

**Cho PowerShell (Windows):**
```powershell
# Đảm bảo bạn đang ở trong thư mục mobile_app
pwd  # Kiểm tra đường dẫn hiện tại (phải là .../mobile_app)

# Core directories
New-Item -ItemType Directory -Force -Path "lib/core/constants"
New-Item -ItemType Directory -Force -Path "lib/core/errors"
New-Item -ItemType Directory -Force -Path "lib/core/network"
New-Item -ItemType Directory -Force -Path "lib/core/theme"
New-Item -ItemType Directory -Force -Path "lib/core/utils"

# Auth feature (complete structure)
New-Item -ItemType Directory -Force -Path "lib/features/auth/data/datasources"
New-Item -ItemType Directory -Force -Path "lib/features/auth/data/repositories"
New-Item -ItemType Directory -Force -Path "lib/features/auth/domain/entities"
New-Item -ItemType Directory -Force -Path "lib/features/auth/domain/usecases"
New-Item -ItemType Directory -Force -Path "lib/features/auth/presentation/bloc"
New-Item -ItemType Directory -Force -Path "lib/features/auth/presentation/pages"
New-Item -ItemType Directory -Force -Path "lib/features/auth/presentation/widgets"

# Other features (basic structure for now)
New-Item -ItemType Directory -Force -Path "lib/features/home/data"
New-Item -ItemType Directory -Force -Path "lib/features/home/domain"
New-Item -ItemType Directory -Force -Path "lib/features/home/presentation"

New-Item -ItemType Directory -Force -Path "lib/features/products/data"
New-Item -ItemType Directory -Force -Path "lib/features/products/domain"
New-Item -ItemType Directory -Force -Path "lib/features/products/presentation"

New-Item -ItemType Directory -Force -Path "lib/features/orders/data"
New-Item -ItemType Directory -Force -Path "lib/features/orders/domain"
New-Item -ItemType Directory -Force -Path "lib/features/orders/presentation"

New-Item -ItemType Directory -Force -Path "lib/features/profile/data"
New-Item -ItemType Directory -Force -Path "lib/features/profile/domain"
New-Item -ItemType Directory -Force -Path "lib/features/profile/presentation"

# Shared directories
New-Item -ItemType Directory -Force -Path "lib/shared/widgets"
New-Item -ItemType Directory -Force -Path "lib/shared/models"
New-Item -ItemType Directory -Force -Path "lib/shared/services"

# Assets directories
New-Item -ItemType Directory -Force -Path "assets/images"
New-Item -ItemType Directory -Force -Path "assets/icons"
New-Item -ItemType Directory -Force -Path "assets/fonts"
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
# Đảm bảo bạn đang ở trong thư mục mobile_app
pwd  # Kiểm tra đường dẫn hiện tại (phải là .../mobile_app)

# Core directories
mkdir -p lib/core/constants
mkdir -p lib/core/errors  
mkdir -p lib/core/network
mkdir -p lib/core/theme
mkdir -p lib/core/utils

# Auth feature (complete structure)
mkdir -p lib/features/auth/data/datasources
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/domain/entities
mkdir -p lib/features/auth/domain/usecases
mkdir -p lib/features/auth/presentation/bloc
mkdir -p lib/features/auth/presentation/pages
mkdir -p lib/features/auth/presentation/widgets

# Other features (basic structure for now)
mkdir -p lib/features/home/data
mkdir -p lib/features/home/domain
mkdir -p lib/features/home/presentation

mkdir -p lib/features/products/data
mkdir -p lib/features/products/domain
mkdir -p lib/features/products/presentation

mkdir -p lib/features/orders/data
mkdir -p lib/features/orders/domain
mkdir -p lib/features/orders/presentation

mkdir -p lib/features/profile/data
mkdir -p lib/features/profile/domain
mkdir -p lib/features/profile/presentation

# Shared directories
mkdir -p lib/shared/widgets
mkdir -p lib/shared/models
mkdir -p lib/shared/services

# Assets directories
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts
```

### 1.4 Cấu hình pubspec.yaml
**⚠️ QUAN TRỌNG: Thay thế TOÀN BỘ nội dung file `pubspec.yaml` hiện tại**

**Cách 1: Copy trực tiếp (Khuyến khích)**
Copy toàn bộ nội dung dưới đây và paste vào file `pubspec.yaml`:

```yaml
name: grocery_shopping_app
description: Grocery Shopping App - Flutter Frontend
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Navigation
  go_router: ^12.1.3
  
  # Networking & JSON
  dio: ^5.3.2
  json_annotation: ^4.8.1
  pretty_dio_logger: ^1.3.1
  
  # UI & Utils
  flutter_screenutil: ^5.9.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  flutter_svg: ^2.0.9
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  
  # Date/Time handling
  intl: ^0.19.0
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # Utilities
  permission_handler: ^11.0.1
  url_launcher: ^6.2.1
  package_info_plus: ^4.2.0
  
  # Icons
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  flutter_lints: ^3.0.0
  bloc_test: ^9.1.5
  hive_generator: ^2.0.1
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
        - asset: assets/fonts/Roboto-Light.ttf
          weight: 300
```

**Cách 2: Copy từ file gốc (Alternative)**
**Cho PowerShell (Windows):**
```powershell
# Copy từ project gốc (nếu có)
Copy-Item "..\pubspec_template.yaml" -Destination "pubspec.yaml" -ErrorAction SilentlyContinue
```

**⚠️ Sau khi cấu hình, PHẢI chạy:**
```powershell
flutter pub get
```

### 1.5 Kiểm tra analysis_options.yaml
File `analysis_options.yaml` đã có sẵn trong project với cấu hình linting phù hợp cho Flutter. 

**Kiểm tra nội dung file:**
**Cho PowerShell (Windows):**
```powershell
Get-Content analysis_options.yaml | Select-Object -First 10
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
head -10 analysis_options.yaml
```

File này đã được cấu hình với:
- ✅ Flutter lints rules
- ✅ Exclude build files và generated files
- ✅ Custom linting rules cho code quality
- ✅ Error handling configuration

**Không cần tạo mới file này!** 📝

---

## 🎯 BƯỚC 2: CORE DEPENDENCIES

### 2.1 Cài đặt packages

**Cho PowerShell (Windows):**
```powershell
flutter pub get
flutter pub deps
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
flutter pub get
flutter pub deps
```

### 2.2 Tạo App Constants
File `lib/core/constants/app_constants.dart` **đã có sẵn** trong project gốc.

**⚠️ LƯU Ý: Đảm bảo bạn đang ở trong thư mục `mobile_app/`**

**Bạn cần COPY file này vào Flutter project:**

**Cho PowerShell (Windows):**
```powershell
# Đảm bảo bạn đang ở trong mobile_app/
cd mobile_app  # Nếu chưa vào

# Copy từ thư mục gốc (đi lên 1 cấp) vào mobile_app
Copy-Item "..\lib\core\constants\app_constants.dart" -Destination "lib\core\constants\app_constants.dart"
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
# Đảm bảo bạn đang ở trong mobile_app/
cd mobile_app  # Nếu chưa vào

# Copy từ thư mục gốc vào mobile_app  
cp ../lib/core/constants/app_constants.dart lib/core/constants/app_constants.dart
```

**Hoặc tạo mới nếu chưa có:**
```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'Grocery Shopping App';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'http://localhost:8080/api';
  static const String apiVersion = 'v1';
  
  // Storage Keys  
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int phoneNumberLength = 10;
}
```

### 2.3 Tạo App Colors & Theme
Các file theme **đã có sẵn** trong project gốc.

**⚠️ LƯU Ý: Đảm bảo bạn đang ở trong thư mục `mobile_app/`**

**Bạn cần COPY các file này vào Flutter project:**

**Cho PowerShell (Windows):**
```powershell
# Copy app_colors.dart
Copy-Item "..\lib\core\theme\app_colors.dart" -Destination "lib\core\theme\app_colors.dart"

# Copy app_theme.dart  
Copy-Item "..\lib\core\theme\app_theme.dart" -Destination "lib\core\theme\app_theme.dart"
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
# Copy app_colors.dart
cp ../lib/core/theme/app_colors.dart lib/core/theme/app_colors.dart

# Copy app_theme.dart
cp ../lib/core/theme/app_theme.dart lib/core/theme/app_theme.dart
```

### 2.4 Tạo Network Config
File `lib/core/network/network_config.dart` **đã có sẵn** trong project gốc.

**Copy vào Flutter project:**

**Cho PowerShell (Windows):**
```powershell
Copy-Item "..\lib\core\network\network_config.dart" -Destination "lib\core\network\network_config.dart"
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
cp ../lib/core/network/network_config.dart lib/core/network/network_config.dart
```

### 2.5 Tạo Error Handling
File `lib/core/errors/failures.dart` **đã có sẵn** trong project gốc.

**Copy vào Flutter project:**

**Cho PowerShell (Windows):**
```powershell
Copy-Item "..\lib\core\errors\failures.dart" -Destination "lib\core\errors\failures.dart"
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
cp ../lib/core/errors/failures.dart lib/core/errors/failures.dart
```

---

## 🎯 BƯỚC 3: BASE WIDGETS

### 3.1 Loading Widget
Tạo file `lib/shared/widgets/loading_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  
  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
  });
  
  const LoadingWidget.small({
    super.key,
    this.message,
    this.color = Colors.white,
  }) : size = 20;
  
  const LoadingWidget.large({
    super.key,
    this.message = 'Đang tải...',
    this.color,
  }) : size = 50;

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = SizedBox(
      width: size?.w ?? 24.w,
      height: size?.h ?? 24.h,
      child: CircularProgressIndicator(
        color: color ?? AppColors.primaryColor,
        strokeWidth: 2.w,
      ),
    );
    
    if (message != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loadingIndicator,
          SizedBox(height: 16.h),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    return loadingIndicator;
  }
}
```

### 3.2 Custom Button Widget
Tạo file `lib/shared/widgets/custom_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import 'loading_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20.w),
          SizedBox(width: 8.w),
        ],
        if (isLoading)
          LoadingWidget.small()
        else
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: textColor ?? (isOutlined ? AppColors.primaryColor : Colors.white),
            ),
          ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height ?? 48.h,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? AppColors.primaryColor,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height ?? 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryColor,
        ),
        child: child,
      );
    );
  }
}
```

### 3.3 Custom Text Field Widget
Tạo file `lib/shared/widgets/custom_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final int? maxLines;
  final bool enabled;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: RichText(
              text: TextSpan(
                text: widget.label,
                style: Theme.of(context).textTheme.labelMedium,
                children: [
                  if (widget.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14.sp,
                      ),
                    ),
                ],
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, size: 20.w)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      size: 20.w,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixWidget,
          ),
        ),
      ],
    );
  }
}
```

---

## 🎯 BƯỚC 4: MAIN APP FILE

### 4.1 Tạo main.dart
Tạo file `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

void main() {
  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart, size: 100.w, color: Colors.white),
              SizedBox(height: 24.h),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Phase 1 Setup Complete!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 50.h),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🎯 BƯỚC 5: TEST & VERIFICATION

### 5.1 Chạy build runner (cho future JSON serialization)

**⚠️ LƯU Ý: Lệnh này chỉ cần thiết khi có JSON serialization. Hiện tại có thể bỏ qua.**

**Nếu muốn chạy (cho tương lai):**

**Cho PowerShell (Windows):**
```powershell
# Lệnh mới (thay thế lệnh cũ đã deprecated)
dart run build_runner build --delete-conflicting-outputs
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
# Lệnh mới (thay thế lệnh cũ đã deprecated)  
dart run build_runner build --delete-conflicting-outputs
```

**Nếu gặp lỗi "Could not find package build_runner", hãy bỏ qua bước này vì:**
- ✅ Phase 1 chưa có JSON models cần generate
- ✅ `build_runner` sẽ cần thiết ở Phase 2 khi tạo models
- ✅ Hiện tại chỉ cần test chạy app thôi

### 5.2 Test chạy app

**Cho PowerShell (Windows):**
```powershell
flutter run
# Hoặc để chạy trên thiết bị cụ thể:
flutter devices        # Xem danh sách thiết bị
flutter run -d chrome  # Chạy trên web browser
flutter run -d windows # Chạy trên Windows desktop
```

**Cho Bash/Terminal (macOS/Linux):**
```bash
flutter run
# Hoặc để chạy trên thiết bị cụ thể:
flutter devices        # Xem danh sách thiết bị  
flutter run -d chrome  # Chạy trên web browser
flutter run -d macos   # Chạy trên macOS (chỉ trên Mac)
```

### 5.3 Kiểm tra Phase 1 hoàn thành
Nếu app chạy thành công và hiển thị Splash Screen với text "Phase 1 Setup Complete!", bạn đã hoàn thành Phase 1!

---

## 📁 **TẠI SAO NÊN TỔ CHỨC NHƯ VẬY?**

### **✅ Lợi ích:**
1. **Quản lý dễ dàng:** Tất cả trong 1 repository
2. **Đồng bộ phát triển:** Backend & Frontend cùng branch
3. **Shared documentation:** Chung README, documentation
4. **CI/CD dễ dàng:** Build cả backend & frontend cùng lúc
5. **Git history:** Track changes của cả 2 phần

### **📂 Cấu trúc cuối cùng sẽ là:**
```
Grocery-Shopping-App/                    # Root repository
├── README.md                           # Tổng quan dự án
├── BACKEND_PLAN.md                     # Kế hoạch backend
├── FRONTEND_PLAN.md                    # Kế hoạch frontend  
├── PHASE1_GUIDE.md                     # Hướng dẫn này
├── .gitignore                          # Git ignore chung
├── server/                             # Backend Spring Boot
│   ├── src/main/java/com/grocery/
│   ├── pom.xml
│   ├── target/
│   └── ...
├── mobile_app/                         # Frontend Flutter
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   ├── shared/
│   │   └── main.dart
│   ├── pubspec.yaml
│   ├── android/
│   ├── ios/
│   ├── build/
│   └── ...
└── docs/                               # Documentation (optional)
    ├── api/
    ├── deployment/
    └── ...
```

### **🚨 TRÁNH TẠO RIÊNG BIỆT:**
```bash
# ❌ KHÔNG làm thế này:
cd d:\DoAnChuyenNganh\
flutter create grocery_shopping_app    # Tạo project riêng

# ✅ ĐÚNG là làm thế này:
cd d:\DoAnChuyenNganh\Grocery-Shopping-App
flutter create mobile_app               # Tạo trong project hiện tại
```

## ✅ CHECKLIST HOÀN THÀNH PHASE 1

- [ ] ✅ Tạo Flutter project
- [ ] ✅ Tạo cấu trúc thư mục clean architecture
- [ ] ✅ Cấu hình pubspec.yaml với tất cả dependencies
- [ ] ✅ Cấu hình analysis_options.yaml
- [ ] ✅ Tạo app constants
- [ ] ✅ Tạo theme system (colors + theme)
- [ ] ✅ Tạo network configuration
- [ ] ✅ Tạo error handling system
- [ ] ✅ Tạo base widgets (Loading, Button, TextField)
- [ ] ✅ Tạo main.dart với splash screen
- [ ] ✅ App chạy thành công không lỗi

## 🚀 TIẾP THEO: PHASE 2

Sau khi hoàn thành Phase 1, bạn có thể bắt đầu Phase 2 - Authentication Module:

1. Setup Dependency Injection (get_it)
2. Tạo Auth entities & models
3. Implement AuthBloc
4. Tạo Login/Register screens
5. Setup GoRouter navigation
6. Kết nối với backend API

---

**Chúc mừng! Bạn đã hoàn thành Phase 1 thành công! 🎉**
