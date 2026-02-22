import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';  // Tạm thời comment
// import '../../core/theme/app_colors.dart';  // Không cần thiết, dùng hardcode

class SnackBarUtils {
  // Prevent instantiation
  SnackBarUtils._();

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF4CAF50), // Green
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F), // Red
      icon: Icons.error,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFFF9800), // Orange
      icon: Icons.warning,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF2196F3), // Blue
      icon: Icons.info,
      duration: duration,
    );
  }

  static void showLoading({
    required BuildContext context,
    String message = 'Đang xử lý...',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16.0), // Thay .w bằng .0
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0, // Thay .sp bằng .0
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF757575), // Grey
        duration: const Duration(minutes: 1), // Long duration cho loading
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Thay .r bằng .0
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Hide current snackbar if showing
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20.0, // Thay .w bằng .0
            ),
            const SizedBox(width: 12.0), // Thay .w bằng .0
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0, // Thay .sp bằng .0
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Thay .r bằng .0
        ),
        action: action,
        margin: const EdgeInsets.all(16.0), // Thay .w/.h bằng .0
      ),
    );
  }

  // Utility method với custom action
  static void showWithAction({
    required BuildContext context,
    required String message,
    required String actionLabel,
    required VoidCallback onActionPressed,
    Color backgroundColor = const Color(0xFF2196F3), // Blue
    IconData icon = Icons.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      action: SnackBarAction(
        label: actionLabel,
        textColor: Colors.white,
        onPressed: onActionPressed,
      ),
    );
  }

  // Utility method cho network errors
  static void showNetworkError({
    required BuildContext context,
    VoidCallback? onRetry,
  }) {
    _showSnackBar(
      context: context,
      message: 'Lỗi kết nối mạng',
      backgroundColor: const Color(0xFFD32F2F), // Red
      icon: Icons.wifi_off,
      duration: const Duration(seconds: 5),
      action: onRetry != null
          ? SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }
}
