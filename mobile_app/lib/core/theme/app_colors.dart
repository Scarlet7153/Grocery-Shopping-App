import 'package:flutter/material.dart';

/// App color palette following Material 3 design and Figma specifications
/// Designed for multi-role grocery shopping app: Customer, Store, Shipper, Admin
class AppColors {
  // ROLE-BASED PRIMARY COLORS (from Figma design)
  
  /// Customer role colors - Blue theme representing trust and reliability
  static const Color customerPrimary = Color(0xFF2196F3);      // Blue
  static const Color customerPrimaryLight = Color(0xFF64B5F6);
  static const Color customerPrimaryDark = Color(0xFF1976D2);
  static const Color customerContainer = Color(0xFFE3F2FD);
  static const Color onCustomerContainer = Color(0xFF0D47A1);
  
  /// Store role colors - Green theme representing growth and freshness  
  static const Color storePrimary = Color(0xFF4CAF50);          // Green
  static const Color storePrimaryLight = Color(0xFF81C784);
  static const Color storePrimaryDark = Color(0xFF388E3C);
  static const Color storeContainer = Color(0xFFE8F5E8);
  static const Color onStoreContainer = Color(0xFF1B5E20);
  
  /// Shipper role colors - Orange theme representing speed and energy
  static const Color shipperPrimary = Color(0xFFFF9800);        // Orange
  static const Color shipperPrimaryLight = Color(0xFFFFB74D);
  static const Color shipperPrimaryDark = Color(0xFFF57C00);
  static const Color shipperContainer = Color(0xFFFFF3E0);
  static const Color onShipperContainer = Color(0xFFE65100);
  
  /// Admin role colors - Purple theme representing authority and management
  static const Color adminPrimary = Color(0xFF9C27B0);          // Purple
  static const Color adminPrimaryLight = Color(0xFFBA68C8);
  static const Color adminPrimaryDark = Color(0xFF7B1FA2);
  static const Color adminContainer = Color(0xFFF3E5F5);
  static const Color onAdminContainer = Color(0xFF4A148C);
  
  // SHARED SYSTEM COLORS (consistent across all roles)
  
  /// Surface Colors - Material 3 standard
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFF3F2F7);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color surfaceContainer = Color(0xFFF7F2FA);
  static const Color surfaceContainerHigh = Color(0xFFECE6F0);
  
  /// Background Colors - Clean and minimal
  static const Color background = Color(0xFFFFFBFE);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color backgroundSecondary = Color(0xFFFAFAFA);
  
  /// Text Colors - Optimized for readability
  static const Color textPrimary = Color(0xFF212121);           // Dark gray
  static const Color textSecondary = Color(0xFF757575);         // Medium gray  
  static const Color textTertiary = Color(0xFF9E9E9E);         // Light gray
  static const Color textHint = Color(0xFFBDBDBD);             // Very light gray
  static const Color textOnDark = Color(0xFFFFFFFF);           // White text
  
  /// Status Colors - Universal feedback colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);
  
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFE65100);
  
  static const Color info = Color(0xFF2196F3);
  static const Color infoContainer = Color(0xFFE3F2FD);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF0D47A1);
  
  /// Border and Divider Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color divider = Color(0xFFE0E0E0);
  
  /// Card and Container Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFAFAFA);
  
  /// Shimmer Loading Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  /// Neutral Colors Palette - Material 3 standard
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
  
  // ROLE-BASED GRADIENTS (for backgrounds and effects)
  
  /// Customer gradients - Blue theme
  static const LinearGradient customerGradient = LinearGradient(
    colors: [customerPrimary, customerPrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient customerGradientReverse = LinearGradient(
    colors: [customerPrimaryLight, customerPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Store gradients - Green theme
  static const LinearGradient storeGradient = LinearGradient(
    colors: [storePrimary, storePrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient storeGradientReverse = LinearGradient(
    colors: [storePrimaryLight, storePrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Shipper gradients - Orange theme
  static const LinearGradient shipperGradient = LinearGradient(
    colors: [shipperPrimary, shipperPrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient shipperGradientReverse = LinearGradient(
    colors: [shipperPrimaryLight, shipperPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Admin gradients - Purple theme
  static const LinearGradient adminGradient = LinearGradient(
    colors: [adminPrimary, adminPrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient adminGradientReverse = LinearGradient(
    colors: [adminPrimaryLight, adminPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// General purpose gradients
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFE57373)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
