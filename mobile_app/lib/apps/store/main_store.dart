import 'package:flutter/material.dart';
import '../../core/theme/store_theme.dart';
import 'screens/auth/store_splash_screen.dart';

void main() {
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đi Chợ Hộ - Chủ Cửa Hàng',
    theme: StoreTheme.lightTheme,
    home: const StoreSplashScreen(),
    debugShowCheckedModeBanner: false,
  );
}