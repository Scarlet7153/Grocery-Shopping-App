/// App Constants - Core configuration values
class AppConstants {
  // App Info
  static const String appName = 'Grocery Shopping App';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:8080/api';
  static const String apiVersion = 'v1';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String getCurrentUserEndpoint = '/auth/me';
  
  // Validation
  static const int phoneNumberLength = 10;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 32;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Timeouts
  static const int connectionTimeoutMs = 30000; // 30 seconds
  static const int receiveTimeoutMs = 30000; // 30 seconds
  
  // Image
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Maps
  static const double defaultLatitude = 10.8231; // Ho Chi Minh City
  static const double defaultLongitude = 106.6297;
  static const double defaultMapZoom = 15.0;
  
  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // UI
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;
  
  // Error Messages
  static const String networkErrorMessage = 'Không có kết nối mạng';
  static const String serverErrorMessage = 'Lỗi server, vui lòng thử lại';
  static const String unknownErrorMessage = 'Đã xảy ra lỗi không xác định';
  
  // Success Messages
  static const String loginSuccessMessage = 'Đăng nhập thành công';
  static const String registerSuccessMessage = 'Đăng ký thành công';
  static const String logoutSuccessMessage = 'Đăng xuất thành công';
  
  // Regex Patterns
  static const String phoneRegex = r'^[0-9]{10}$';
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  
  // Firebase
  static const String fcmTopic = 'grocery_app_notifications';
}
