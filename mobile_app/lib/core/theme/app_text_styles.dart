import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography system following Material 3 design and Figma specifications
/// Optimized for multi-role grocery shopping app with Vietnamese language support
class AppTextStyles {
  // DISPLAY TEXT STYLES - For large titles and branding
  
  /// Display Large - App title, welcome screens
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    color: AppColors.textPrimary,
  );
  
  /// Display Medium - Page headers, important announcements
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
    color: AppColors.textPrimary,
  );
  
  /// Display Small - Section headers, card titles
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
    color: AppColors.textPrimary,
  );
  
  // HEADLINE TEXT STYLES - For section titles and important content
  
  /// Headline Large - Auth screen titles, main page headers
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700, // Bold for Vietnamese readability
    letterSpacing: 0,
    height: 1.25,
    color: AppColors.textPrimary,
  );
  
  /// Headline Medium - Screen titles, modal headers  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600, // Semi-bold
    letterSpacing: 0,
    height: 1.29,
    color: AppColors.textPrimary,
  );
  
  /// Headline Small - Card headers, form section titles
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: AppColors.textPrimary,
  );
  
  // TITLE TEXT STYLES - For content hierarchy
  
  /// Title Large - List item titles, important labels
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500, // Medium weight
    letterSpacing: 0,
    height: 1.27,
    color: AppColors.textPrimary,
  );
  
  /// Title Medium - Subtitle, secondary headers
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  /// Title Small - Small headers, emphasized text
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );
  
  // LABEL TEXT STYLES - For UI elements
  
  /// Label Large - Button text, navigation labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600, // Semi-bold for buttons
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textPrimary,
  );
  
  /// Label Medium - Input labels, small buttons
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textSecondary,
  );
  
  /// Label Small - Captions, metadata
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
    color: AppColors.textTertiary,
  );
  
  // BODY TEXT STYLES - For content and descriptions
  
  /// Body Large - Main content, descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  /// Body Medium - Secondary content, list items
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textPrimary,
  );
  
  /// Body Small - Supporting text, metadata
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textSecondary,
  );
  
  // SPECIALIZED TEXT STYLES - For specific UI components
  
  // Button Text Styles
  /// Button Large - Primary action buttons
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.25,
    color: AppColors.textOnDark,
  );
  
  /// Button Medium - Secondary buttons, dialog actions
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.29,
    color: AppColors.textOnDark,
  );
  
  /// Button Small - Tertiary buttons, links
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textOnDark,
  );
  
  // Input Field Text Styles
  /// Input Text - Text inside input fields
  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  /// Input Label - Labels for input fields
  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textSecondary,
  );
  
  /// Input Hint - Placeholder text in inputs
  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.textHint,
  );
  
  /// Input Error - Error messages for validation
  static const TextStyle inputError = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.error,
  );
  
  /// Input Helper - Helper text for inputs
  static const TextStyle inputHelper = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.textTertiary,
  );
  
  // Navigation and UI Text Styles
  /// Navigation Label - Bottom navigation, tabs
  static const TextStyle navigationLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textSecondary,
  );
  
  /// Navigation Active - Active navigation items
  static const TextStyle navigationActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: AppColors.textPrimary,
  );
  
  // Status and Feedback Text Styles
  /// Success Text - Success messages and confirmations
  static const TextStyle successText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.success,
  );
  
  /// Warning Text - Warning messages
  static const TextStyle warningText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.warning,
  );
  
  /// Error Text - Error messages and alerts
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.error,
  );
  
  /// Info Text - Information and tips
  static const TextStyle infoText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.info,
  );
  
  // Price and Currency Text Styles
  /// Price Large - Main product prices
  static const TextStyle priceLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.storePrimary,
  );
  
  /// Price Medium - Secondary prices, discounts
  static const TextStyle priceMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.storePrimary,
  );
  
  /// Price Small - Small prices, currency symbols
  static const TextStyle priceSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    color: AppColors.textSecondary,
  );
  
  /// Price Discount - Crossed out original prices
  static const TextStyle priceDiscount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textTertiary,
  );
  
  // ROLE-BASED TEXT STYLES - Colored text for different user roles
  
  /// Customer role text - Blue theme
  static TextStyle customerRoleText = titleMedium.copyWith(
    color: AppColors.customerPrimary,
    fontWeight: FontWeight.w600,
  );
  
  /// Store role text - Green theme  
  static TextStyle storeRoleText = titleMedium.copyWith(
    color: AppColors.storePrimary,
    fontWeight: FontWeight.w600,
  );
  
  /// Shipper role text - Orange theme
  static TextStyle shipperRoleText = titleMedium.copyWith(
    color: AppColors.shipperPrimary,
    fontWeight: FontWeight.w600,
  );
  
  /// Admin role text - Purple theme
  static TextStyle adminRoleText = titleMedium.copyWith(
    color: AppColors.adminPrimary,
    fontWeight: FontWeight.w600,
  );
}
