# 📱 Grocery Shopping App - Multi-Platform Flutter Application

> **Ứng dụng đi chợ hộ đa nền tảng với 4 giao diện riêng biệt: Customer, Store, Shipper & Admin**

## 🎯 Tổng Quan Dự Án

**Grocery Shopping App** là một hệ sinh thái hoàn chỉnh được xây dựng trên Flutter, cung cấp 4 ứng dụng độc lập trong cùng một codebase:

- 🛒 **Customer App** - Khách hàng đặt hàng và theo dõi
- 🏪 **Store App** - Chủ cửa hàng quản lý bán hàng  
- 🚚 **Shipper App** - Người giao hàng nhận và giao đơn
- 👑 **Admin App** - Quản trị viên điều hành hệ thống

### ✨ Đặc Điểm Nổi Bật
- **Multi-App Architecture** - 4 apps trong 1 codebase
- **Clean Architecture** - Dễ bảo trì và mở rộng
- **Material 3 Design** - Giao diện hiện đại
- **Cross-Platform** - Chạy trên mọi thiết bị
- **Theme-Based** - Mỗi app có theme riêng

---

## 🛠️ Công Nghệ Sử Dụng

| Công Nghệ | Version | Mục Đích |
|-----------|---------|----------|
| **Flutter** | >=3.10.0 | Framework đa nền tảng |
| **Dart** | >=3.0.0 | Ngôn ngữ lập trình |
| **flutter_bloc** | ^8.1.3 | Quản lý trạng thái |
| **go_router** | ^12.1.1 | Điều hướng nâng cao |
| **dio** | ^5.3.2 | HTTP Client |
| **hive** | ^2.2.3 | Lưu trữ local |
| **shared_preferences** | ^2.2.2 | Cài đặt ứng dụng |
| **cached_network_image** | ^3.3.0 | Cache hình ảnh |

---

## 🚀 Hướng Dẫn Cài Đặt

### 📋 Yêu Cầu Hệ Thống

**Bắt buộc:**
- Flutter SDK >=3.10.0
- Dart SDK >=3.0.0
- Git
- VS Code hoặc Android Studio

**Tùy chọn (theo nền tảng):**
- Android Studio (cho Android)
- Xcode (cho iOS - chỉ macOS)
- Chrome Browser (cho Web)

### 🔧 Các Bước Cài Đặt

#### 1️⃣ Clone Repository
```bash
git clone <repository-url>
cd Grocery-Shopping-App/mobile_app
```

#### 2️⃣ Kiểm Tra Flutter
```bash
flutter doctor
```
> Đảm bảo tất cả checkmarks đều ✅

#### 3️⃣ Cài Đặt Dependencies  
```bash
flutter pub get
```

#### 4️⃣ Tạo Generated Files (Nếu cần)
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 5️⃣ Kiểm Tra Thiết Bị
```bash
flutter devices
```

---

## 🔄 Chuyển Đổi Giữa Các App

### 🎛️ Cấu Hình App Type

**Bước 1:** Mở file cấu hình
```bash
# Đường dẫn: mobile_app/lib/core/config/app_config.dart
```

**Bước 2:** Thay đổi `currentApp`
```dart
// filepath: lib/core/config/app_config.dart
class AppConfig {
  // 🔄 THAY ĐỔI DÒNG NÀY để chuyển app
  static AppType currentApp = AppType.customer;
  
  // 4 Tùy chọn:
  // AppType.customer  🛒 - Màu xanh lá (#4CAF50)
  // AppType.store     🏪 - Màu xanh dương (#2196F3)  
  // AppType.shipper   🚚 - Màu cam (#FF9800)
  // AppType.admin     👑 - Màu tím (#9C27B0)
}
```

**Bước 3:** Restart App
```bash
# Trong terminal đang chạy app, nhấn:
R    # Hot Restart để áp dụng thay đổi
```

### 🎨 App Themes & Features

| App Type | Theme Color | Icon | Target User | Key Features |
|----------|-------------|------|-------------|--------------|
| **🛒 Customer** | Xanh lá #4CAF50 | shopping_cart | Người mua | Đặt hàng, thanh toán, theo dõi |
| **🏪 Store** | Xanh dương #2196F3 | storefront | Chủ shop | Quản lý sản phẩm, đơn hàng |
| **🚚 Shipper** | Cam #FF9800 | delivery_dining | Shipper | GPS, giao hàng, thu tiền |
| **👑 Admin** | Tím #9C27B0 | admin_panel_settings | Admin | Dashboard, thống kê, quản lý |

---

## 📱 Chạy Ứng Dụng

### 🏃‍♂️ Quick Start
```bash
# Chạy app với auto-detect device
flutter run
```

### 📱 Mobile Platforms

#### Android
```bash
# Chạy trên Android device/emulator
flutter run -d android

# Build APK
flutter build apk --release
```

#### iOS (chỉ macOS)
```bash
# Chạy trên iOS Simulator
flutter run -d ios

# Build for iOS
flutter build ios --release
```

### 🌐 Web Platform
```bash
# Chạy trên Chrome (recommended)
flutter run -d chrome

# Chạy với port tùy chỉnh
flutter run -d chrome --web-port 8080

# Build for web
flutter build web --release
```

### Chuyển đổi run app ###
1. Truy cập theo đường dẫn: ..\Grocery-Shopping-App\mobile_app\lib\core\config\app_config.dart
2. Bỏ comment để run app. VD: static const AppType currentApp = AppType.customer;


### 💻 Desktop Platforms

#### Windows
```bash
# Chạy trên Windows
flutter run -d windows

# Build Windows app
flutter build windows --release
```

#### macOS
```bash
# Chạy trên macOS  
flutter run -d macos

# Build macOS app
flutter build macos --release
```

#### Linux
```bash
# Chạy trên Linux
flutter run -d linux

# Build Linux app
flutter build linux --release
```

### ⚡ Development Modes

| Mode | Command | Purpose |
|------|---------|---------|
| **Debug** | `flutter run --debug` | Development với hot reload |
| **Profile** | `flutter run --profile` | Performance testing |
| **Release** | `flutter run --release` | Production-like performance |

**Hot Reload Shortcuts:**
- `r` - Hot reload (nhanh)
- `R` - Hot restart (đầy đủ)  
- `h` - Help menu
- `q` - Quit app

---

## 🏗️ Cấu Trúc Dự Án

```
mobile_app/
├── 📂 lib/
│   ├── 🎯 apps/                    # 4 Apps riêng biệt
│   │   ├── customer/               # 🛒 Customer App
│   │   │   ├── screens/            # Màn hình Customer
│   │   │   └── widgets/            # Widget Customer
│   │   ├── store/                  # 🏪 Store App
│   │   │   ├── screens/            # Màn hình Store
│   │   │   └── widgets/            # Widget Store
│   │   ├── shipper/                # 🚚 Shipper App
│   │   │   ├── screens/            # Màn hình Shipper  
│   │   │   └── widgets/            # Widget Shipper
│   │   └── admin/                  # 👑 Admin App
│   │       ├── screens/            # Màn hình Admin
│   │       └── widgets/            # Widget Admin
│   ├── ⚙️ core/                    # Core System
│   │   ├── config/                 # 🔄 App Config (Switch Apps)
│   │   ├── constants/              # Hằng số
│   │   ├── errors/                 # Xử lý lỗi
│   │   ├── network/                # API client
│   │   ├── theme/                  # 4 App themes
│   │   └── utils/                  # Utilities
│   ├── 🔒 features/                # Business Features
│   │   ├── auth/                   # Authentication
│   │   ├── products/               # Product management
│   │   ├── orders/                 # Order management
│   │   ├── delivery/               # Delivery system
│   │   └── analytics/              # Analytics & reports
│   ├── 🔗 shared/                  # Shared Components
│   │   ├── widgets/                # Reusable widgets
│   │   ├── models/                 # Data models
│   │   ├── services/               # Shared services
│   │   └── repositories/           # Data repositories
│   └── 🚀 main.dart               # App entry point
├── 📁 assets/                      # Static Assets
│   ├── images/                     # App images
│   ├── icons/                      # App icons  
│   └── fonts/                      # Custom fonts
├── 🤖 android/                     # Android specific
├── 🍎 ios/                         # iOS specific
├── 🌐 web/                         # Web specific
├── 💻 windows/                     # Windows specific
├── 📄 pubspec.yaml                # Dependencies
└── 📖 README.md                   # This file
```

## 👥 Development Team

### 🚀 Frontend Team
| STT | Tên | MSSV | Vai trò |
|-----|-----|------|---------|
| 1 | **Đàm Thị Ngọc Châu** | 3122411020 | 👑 **Team Leader** |
| 2 | Phan Thị Hải Vân | 3122411243 | Frontend Developer |  
| 3 | Võ Hoàng Kim Quyên | 3122411173 | Frontend Developer |
| 4 | Lê Gia Hân | 3122411049 | Frontend Developer |
| 5 | Phan Thị Hồng Nhiên | 3122411141 | Frontend Developer |


*Last updated: March 2026*