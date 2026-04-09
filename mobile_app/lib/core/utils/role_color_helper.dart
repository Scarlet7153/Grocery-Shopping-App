import 'package:flutter/material.dart';
import '../enums/user_role.dart';
import '../theme/app_colors.dart';

/// Utility class for role-based color operations
/// Provides convenient methods to get colors based on user roles
class RoleColorHelper {
  /// Get primary color for a specific role
  static Color getPrimaryColor(UserRole role) {
    return role.primaryColor;
  }

  /// Get light variant color for a specific role
  static Color getLightColor(UserRole role) {
    return role.lightColor;
  }

  /// Get dark variant color for a specific role
  static Color getDarkColor(UserRole role) {
    return role.darkColor;
  }

  /// Get container color for a specific role
  static Color getContainerColor(UserRole role) {
    return role.containerColor;
  }

  /// Get gradient for a specific role
  static LinearGradient getGradient(UserRole role) {
    return role.gradient;
  }

  /// Get text color that contrasts well with role's primary color
  static Color getTextColorOnPrimary(UserRole role) {
    return AppColors.textOnDark;
  }

  /// Get text color that contrasts well with role's container color
  static Color getTextColorOnContainer(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return AppColors.onCustomerContainer;
      case UserRole.store:
        return AppColors.onStoreContainer;
      case UserRole.shipper:
        return AppColors.onShipperContainer;
      case UserRole.admin:
        return AppColors.onAdminContainer;
    }
  }

  /// Get a subtle background color for role-specific sections
  static Color getSubtleBackground(UserRole role) {
    return role.containerColor.withValues(alpha: 0.1);
  }

  /// Get border color for role-specific UI elements
  static Color getBorderColor(UserRole role) {
    return role.primaryColor.withValues(alpha: 0.3);
  }

  /// Get icon color for role-specific icons
  static Color getIconColor(UserRole role, {bool isActive = false}) {
    if (isActive) {
      return role.primaryColor;
    }
    return AppColors.textSecondary;
  }

  /// Get button colors based on role and button type
  static ButtonStyle getRoleButtonStyle(
    UserRole role, {
    bool isOutlined = false,
    bool isText = false,
  }) {
    if (isText) {
      return TextButton.styleFrom(
        foregroundColor: role.primaryColor,
        overlayColor: role.primaryColor.withValues(alpha: 0.1),
      );
    }

    if (isOutlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: role.primaryColor,
        side: BorderSide(color: role.primaryColor),
        overlayColor: role.primaryColor.withValues(alpha: 0.1),
      );
    }

    // Filled button (default)
    return ElevatedButton.styleFrom(
      backgroundColor: role.primaryColor,
      foregroundColor: AppColors.textOnDark,
      overlayColor: Colors.white.withValues(alpha: 0.1),
    );
  }

  /// Get chip colors based on role
  static ChipThemeData getRoleChipTheme(UserRole role) {
    return ChipThemeData(
      backgroundColor: role.containerColor,
      labelStyle: TextStyle(color: getTextColorOnContainer(role)),
      side: BorderSide(color: role.primaryColor.withValues(alpha: 0.3)),
      selectedColor: role.primaryColor,
    );
  }

  /// Get app bar colors based on role
  static AppBarTheme getRoleAppBarTheme(UserRole role) {
    return AppBarTheme(
      backgroundColor: role.primaryColor,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textOnDark),
      actionsIconTheme: const IconThemeData(color: AppColors.textOnDark),
    );
  }

  /// Get floating action button colors based on role
  static Color getFABColor(UserRole role) {
    return role.primaryColor;
  }

  /// Get bottom navigation bar colors based on role
  static BottomNavigationBarThemeData getRoleBottomNavTheme(UserRole role) {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: role.primaryColor,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  /// Get input decoration theme based on role
  static InputDecorationTheme getRoleInputTheme(UserRole role) {
    return InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: role.primaryColor, width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.border),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }

  /// Get switch colors based on role
  static Color getSwitchActiveColor(UserRole role) {
    return role.primaryColor;
  }

  /// Get slider colors based on role
  static SliderThemeData getRoleSliderTheme(UserRole role) {
    return SliderThemeData(
      activeTrackColor: role.primaryColor,
      thumbColor: role.primaryColor,
      overlayColor: role.primaryColor.withValues(alpha: 0.2),
      inactiveTrackColor: role.primaryColor.withValues(alpha: 0.3),
    );
  }

  /// Get progress indicator colors based on role
  static Color getProgressColor(UserRole role) {
    return role.primaryColor;
  }

  /// Get card elevation and colors for role-specific cards
  static BoxDecoration getRoleCardDecoration(
    UserRole role, {
    bool isElevated = true,
    bool hasGradient = false,
  }) {
    if (hasGradient) {
      return BoxDecoration(
        gradient: role.gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isElevated
            ? [
                BoxShadow(
                  color: role.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      );
    }

    return BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: getBorderColor(role)),
      borderRadius: BorderRadius.circular(12),
      boxShadow: isElevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Get role-specific selection indicator color
  static Color getSelectionColor(UserRole role) {
    return role.primaryColor.withValues(alpha: 0.2);
  }

  /// Get role-specific ripple effect color
  static Color getRippleColor(UserRole role) {
    return role.primaryColor.withValues(alpha: 0.1);
  }

  /// Check if a color is dark (for automatic text color selection)
  static bool isDarkColor(Color color) {
    return color.computeLuminance() < 0.5;
  }

  /// Get automatic text color based on background color
  static Color getTextColorForBackground(Color backgroundColor) {
    return isDarkColor(backgroundColor)
        ? AppColors.textOnDark
        : AppColors.textPrimary;
  }
}
