import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = {
    'vi': {
      'app_title': 'Quản trị Grocery',
      'nav_overview': 'Tổng quan',
      'nav_users': 'Người dùng',
      'nav_stores': 'Cửa hàng',
      'nav_shippers': 'Giao hàng',
      'nav_orders': 'Đơn hàng',
      'nav_delivery': 'Vận chuyển',
      'nav_settings': 'Cài đặt',
      'settings_title': 'Cài đặt hệ thống',
      'settings_account': 'TÀI KHOẢN QUẢN TRỊ',
      'settings_personal': 'Thông tin cá nhân',
      'settings_security': 'Bảo mật & Mật khẩu',
      'settings_customization': 'TÙY CHỈNH TRẢI NGHIỆM',
      'settings_notifications': 'Thông báo đẩy',
      'settings_dark_mode': 'Giao diện ứng dụng',
      'settings_language': 'Ngôn ngữ hiển thị',
      'settings_support': 'HỖ TRỢ & PHÁP LÝ',
      'settings_about': 'Về ứng dụng',
      'settings_logout': 'ĐĂNG XUẤT TÀI KHOẢN',
      'edit_profile': 'Cập nhật Thông tin',
      'save_changes': 'LƯU THAY ĐỔI',
      'full_name': 'Họ và tên',
      'dark_mode_on': 'Chế độ Tối',
      'dark_mode_off': 'Chế độ Sáng',
      'greeting_morning': 'Chào buổi sáng',
      'greeting_afternoon': 'Chào buổi chiều',
      'greeting_evening': 'Chào buổi tối',
      'greeting_welcome_back': 'Chào mừng bạn trở lại',
    },
    'en': {
      'app_title': 'Grocery Admin',
      'nav_overview': 'Overview',
      'nav_users': 'Users',
      'nav_stores': 'Stores',
      'nav_shippers': 'Shippers',
      'nav_orders': 'Orders',
      'nav_delivery': 'Delivery',
      'nav_settings': 'Settings',
      'settings_title': 'System Settings',
      'settings_account': 'ADMIN ACCOUNT',
      'settings_personal': 'Personal Information',
      'settings_security': 'Security & Password',
      'settings_customization': 'EXPERIENCE CUSTOMIZATION',
      'settings_notifications': 'Push Notifications',
      'settings_dark_mode': 'App Appearance',
      'settings_language': 'Display Language',
      'settings_support': 'SUPPORT & LEGAL',
      'settings_about': 'About App',
      'settings_logout': 'LOGOUT ACCOUNT',
      'edit_profile': 'Edit Profile',
      'save_changes': 'SAVE CHANGES',
      'full_name': 'Full Name',
      'dark_mode_on': 'Dark Mode',
      'dark_mode_off': 'Light Mode',
      'greeting_morning': 'Good Morning',
      'greeting_afternoon': 'Good Afternoon',
      'greeting_evening': 'Good Evening',
      'greeting_welcome_back': 'Welcome back',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String byLocale({required String vi, required String en}) {
    return locale.languageCode == 'en' ? en : vi;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
