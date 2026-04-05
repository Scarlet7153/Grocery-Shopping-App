🛒 Grocery Shopping App - Hệ sinh thái 4-trong-1

Ứng dụng đi chợ hộ đa nền tảng được xây dựng trên Flutter & Spring Boot.

🎯 Tổng Quan Dự Án

Dự án cung cấp giải pháp toàn diện cho việc đi chợ hộ với 4 giao diện người dùng riêng biệt tích hợp trong cùng một mã nguồn (Single Codebase):

🛒 Customer App: Dành cho khách hàng tìm kiếm, đặt hàng và theo dõi đơn.

🏪 Store App: Dành cho chủ cửa hàng quản lý sản phẩm và xử lý đơn hàng.

🚚 Shipper App: Dành cho người giao hàng với hệ thống điều hướng và cập nhật trạng thái.

👑 Admin App: Dành cho quản trị viên điều hành hệ thống và xem báo cáo thống kê.

🛠 Công Nghệ Sử Dụng

Frontend: Flutter 3.10+, BLoC Pattern, Dio, Hive, GoRouter

Backend: Java Spring Boot (Maven), RESTful API

Thiết kế: Material 3, Clean Architecture, Theme-based

🚀 Hướng Dẫn Chạy Nhanh

1️⃣ Khởi động Backend

Mở Terminal tại thư mục backend:

cd backend
.\mvnw.cmd spring-boot:run


2️⃣ Khởi động Frontend

Mở Terminal tại thư mục mobile_app:

cd mobile_app
flutter pub get
# Chạy mặc định trên trình duyệt Chrome
flutter run -d chrome --target lib/apps/customer/main_customer.dart


🔄 Cách Chuyển Đổi Giữa Các App (Role)

Để thay đổi vai trò người dùng trong quá trình phát triển:

Mở file: lib/core/config/app_config.dart

Thay đổi giá trị tại dòng currentApp:
static const AppType currentApp = AppType.customer;
(Các tùy chọn: .customer | .store | .shipper | .admin)

Hot Restart (Nhấn R) trên Terminal để áp dụng.

📂 Cấu Trúc Mã Nguồn Rút Gọn

mobile_app/
├── 🎯 lib/apps/       # 4 Phân hệ người dùng độc lập
├── ⚙️ lib/core/       # Config, Theme, Network client
├── 🔒 lib/features/   # Tính năng nghiệp vụ (Auth, Orders, Products)
├── 🔗 lib/shared/     # Widget, Model, Service dùng chung
└── 🚀 lib/main.dart   # Điểm khởi chạy ứng dụng


👥 Đội Ngũ Phát Triển (Frontend Team)

1. Đàm Thị Ngọc Châu (3122411020) - 👑 Team Leader
2. Phan Thị Hải Vân (3122411243) - Frontend Developer
3. Võ Hoàng Kim Quyên (3122411173) - Frontend Developer
4. Lê Gia Hân (3122411049) - Frontend Developer
5. Phan Thị Hồng Nhiên (3122411141) - Frontend Developer
