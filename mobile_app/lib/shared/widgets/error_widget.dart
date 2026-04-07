import 'package:flutter/material.dart';
import 'buttons/custom_button.dart'; // Fixed import path

class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final Widget? icon;

  const CustomErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.buttonText,
    this.onRetry,
    this.icon,
  });

  const CustomErrorWidget.network({
    super.key,
    this.title = 'Lỗi kết nối',
    this.message =
        'Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet.',
    this.buttonText = 'Thử lại',
    this.onRetry,
  }) : icon = const Icon(Icons.wifi_off, size: 64, color: Colors.red);

  const CustomErrorWidget.notFound({
    super.key,
    this.title = 'Không tìm thấy',
    this.message = 'Dữ liệu bạn tìm kiếm không tồn tại.',
    this.buttonText,
    this.onRetry,
  }) : icon = const Icon(Icons.search_off, size: 64, color: Colors.grey);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: 24.0),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD32F2F),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
          ],
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF757575),
                ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null && buttonText != null) ...[
            const SizedBox(height: 24.0),
            CustomButton(
              // Fixed - Now properly imports and uses CustomButton
              text: buttonText!,
              onPressed: onRetry,
              type: ButtonType.primary, // Use proper ButtonType enum
              customColor: const Color(0xFF4CAF50),
            ),
          ],
        ],
      ),
    );
  }
}
