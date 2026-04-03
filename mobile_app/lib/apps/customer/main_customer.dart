import 'package:flutter/material.dart';
import '../../core/theme/customer_theme.dart';
import 'screens/auth/customer_splash_screen.dart';

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đi Chợ Hộ - Khách Hàng',
    theme: CustomerTheme.lightTheme,
    home: const CustomerSplashScreen(),
    debugShowCheckedModeBanner: false,
  );
}