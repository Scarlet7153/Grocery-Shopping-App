import 'package:flutter/material.dart';

/// App color palette following Material 3 design
class AppColors {
  // Primary Colors - Green Theme
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color primaryVariant = Color(0xFF388E3C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  // Secondary Colors - Orange Theme
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color secondaryVariant = Color(0xFFF57C00);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFF3F2F7);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  
  // Background Colors
  static const Color background = Color(0xFFFFFBFE);
  static const Color onBackground = Color(0xFF1C1B1F);
  
  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);
  
  // Success Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);
  
  // Warning Colors
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFE65100);
  
  // Info Colors
  static const Color info = Color(0xFF2196F3);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF0D47A1);
  
  // Neutral Colors
  static const Color neutral10 = Color(0xFF1C1B1F);
  static const Color neutral20 = Color(0xFF313033);
  static const Color neutral30 = Color(0xFF484649);
  static const Color neutral40 = Color(0xFF605D62);
  static const Color neutral50 = Color(0xFF787579);
  static const Color neutral60 = Color(0xFF939094);
  static const Color neutral70 = Color(0xFFAEAAAE);
  static const Color neutral80 = Color(0xFFCAC5CA);
  static const Color neutral90 = Color(0xFFE6E0E9);
  static const Color neutral95 = Color(0xFFF4EFF4);
  static const Color neutral99 = Color(0xFFFFFBFE);
  
  // App Specific Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
