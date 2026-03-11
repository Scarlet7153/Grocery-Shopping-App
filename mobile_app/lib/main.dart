import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

void main() => runApp(const GroceryApp());

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
        ),
    );
}

/// Temporary splash screen for Phase 1
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50), // Primary green
              Color(0xFF388E3C), // Darker green
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 100.w,
                color: Colors.white,
              ),
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
                'Phase 1: Setup Complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 50.h),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.w,
              ),
            ],
          ),
        ),
      ),
    );
}