import 'package:flutter/material.dart';
import '../../core/theme/shipper_theme.dart';
import 'screens/auth/shipper_splash_screen.dart';

void main() {
  runApp(const ShipperApp());
}

class ShipperApp extends StatelessWidget {
  const ShipperApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Đi Chợ Hộ - Shipper',
    theme: ShipperTheme.lightTheme,
    home: const ShipperSplashScreen(),
    debugShowCheckedModeBanner: false,
  );
}