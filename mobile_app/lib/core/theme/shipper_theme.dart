import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShipperTheme {
  // ===== PRIMARY COLORS =====
  static const Color primaryColor = Color(0xFFFF9800); // Orange - CTA, active
  static const Color secondaryColor = Color(0xFF007AFF); // Blue - Info
  static const Color successColor = Color(0xFF34C759); // Green - Delivered
  static const Color dangerColor = Color(0xFFFF3B30); // Red - Failed
  static const Color warningColor = Color(0xFFFF9500); // Orange - Warning

  // ===== NEUTRAL COLORS =====
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Colors.white;
  static const Color textDarkColor = Color(0xFF000000);
  static const Color textColor = textDarkColor; // Backwards compatibility
  static const Color textGreyColor = Color(0xFF3C3C43);
  static const Color textLightGreyColor = Color(0xFF8E8E93);
  static const Color borderColor = Color(0xFFE5E5EA);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
          surfaceContainerLowest: backgroundColor,
          error: dangerColor,
          errorContainer: dangerColor.withValues(alpha: 0.1),
        ),

        // ===== TYPOGRAPHY =====
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            // Display sizes (typically 32-34px)
            displayLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textDarkColor,
            ),

            // Headline sizes (24px)
            headlineLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textDarkColor,
            ),

            // H2 (20px)
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: textDarkColor,
            ),

            // H3 (18px) - Card titles
            headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: textDarkColor,
            ),

            // Title Large (16px) - Button text, important labels
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDarkColor,
            ),

            // Title Medium (14px)
            titleMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textDarkColor,
            ),

            // Body Large (16px) - MAIN BODY TEXT ⭐
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: textDarkColor,
            ),

            // Body Medium (15px)
            bodyMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: textGreyColor,
            ),

            // Body Small (14px)
            bodySmall: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: textGreyColor,
            ),

            // Label Large (14px) - Labels, small buttons
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textDarkColor,
            ),

            // Label Medium (12px)
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textGreyColor,
            ),

            // Label Small (11px)
            labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textLightGreyColor,
            ),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            minimumSize: const Size(48, 56), // 56px height CTA
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            minimumSize: const Size(48, 56),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textLightGreyColor,
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDarkColor,
          ),
        ),
      );

  // ===== UTILITY COLORS =====
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PICKING_UP':
        return primaryColor;
      case 'DELIVERING':
        return secondaryColor;
      case 'DELIVERED':
        return successColor;
      case 'FAILED':
      case 'REJECTED':
        return dangerColor;
      default:
        return textLightGreyColor;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PICKING_UP':
        return Icons.store;
      case 'DELIVERING':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.cancel;
      case 'REJECTED':
        return Icons.block;
      default:
        return Icons.info;
    }
  }
}
