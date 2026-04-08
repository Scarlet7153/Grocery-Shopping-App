import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';  // Tạm thời comment
// import '../../core/theme/app_colors.dart';  // Không cần thiết, dùng hardcode
import 'buttons/custom_button.dart';

class CustomDialog extends StatelessWidget {
  final String? title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? icon;
  final bool barrierDismissible;

  const CustomDialog({
    super.key,
    this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.barrierDismissible = true,
  });

  const CustomDialog.confirm({
    super.key,
    this.title = 'Xác nhận',
    required this.message,
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy',
    this.onConfirm,
    this.onCancel,
    this.barrierDismissible = true,
  }) : icon = const Icon(
         Icons.help_outline,
         size: 48,
         color: Color(0xFF2196F3),
       );

  const CustomDialog.warning({
    super.key,
    this.title = 'Cảnh báo',
    required this.message,
    this.confirmText = 'Đồng ý',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.barrierDismissible = true,
  }) : icon = const Icon(
         Icons.warning_amber,
         size: 48,
         color: Color(0xFFFF9800),
       );

  const CustomDialog.error({
    super.key,
    this.title = 'Lỗi',
    required this.message,
    this.confirmText = 'Đóng',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.barrierDismissible = true,
  }) : icon = const Icon(
         Icons.error_outline,
         size: 48,
         color: Color(0xFFD32F2F),
       );

  const CustomDialog.success({
    super.key,
    this.title = 'Thành công',
    required this.message,
    this.confirmText = 'Đóng',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.barrierDismissible = true,
  }) : icon = const Icon(
         Icons.check_circle_outline,
         size: 48,
         color: Color(0xFF4CAF50),
       );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Thay .r bằng .0
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Thay .w/.h bằng .0
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: 16.0), // Thay .h bằng .0
            ],
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0), // Thay .h bằng .0
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0), // Thay .h bằng .0
            Row(
              children: [
                if (cancelText != null && onCancel != null) ...[
                  Expanded(
                    child: CustomButton(
                      text: cancelText!,
                      onPressed: onCancel,
                      type: ButtonType
                          .secondary, // Fixed - Use ButtonType.secondary instead of outlined
                    ),
                  ),
                  const SizedBox(width: 12.0),
                ],
                if (confirmText != null) ...[
                  Expanded(
                    child: CustomButton(
                      text: confirmText!,
                      onPressed: onConfirm ?? () => Navigator.of(context).pop(),
                      type:
                          ButtonType.primary, // Fixed - Use ButtonType.primary
                      customColor: const Color(
                        0xFF4CAF50,
                      ), // Fixed - Use customColor instead of backgroundColor
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Static methods để show dialog dễ dàng
  static Future<bool?> showConfirm({
    required BuildContext context,
    String? title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog.confirm(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    String? title,
    required String message,
    String? confirmText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomDialog.error(
        title: title,
        message: message,
        confirmText: confirmText,
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    String? title,
    required String message,
    String? confirmText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomDialog.success(
        title: title,
        message: message,
        confirmText: confirmText,
      ),
    );
  }
}
