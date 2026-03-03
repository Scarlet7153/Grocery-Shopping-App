import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';
import 'screens/auth/admin_splash_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override  
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đi Chợ Hộ - Quản Trị Viên',
    theme: AdminTheme.lightTheme,
    home: const AdminSplashScreen(),
    debugShowCheckedModeBanner: false,
  );
}

// Email: admin@dichoho.com
// Password: admin123

// Email: superadmin@dichoho.com  
// Password: super123