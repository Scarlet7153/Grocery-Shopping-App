import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../core/theme/app_colors.dart';  // Không cần thiết, dùng hardcode
import 'loading_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20.0), // Thay .w
          const SizedBox(width: 8.0), // Thay .w
        ],
        if (isLoading)
          const LoadingWidget.small()
        else
          Text(
            text,
            style: TextStyle(
              fontSize: 16.0, // Thay .sp
              fontWeight: FontWeight.w600,
              color: textColor ?? (isOutlined ? const Color(0xFF4CAF50) : Colors.white), // Hardcode AppColors.primaryColor
            ),
          ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: width,
        height: height ?? 48.0, // Thay .h
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? const Color(0xFF4CAF50), // Hardcode AppColors.primaryColor
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height ?? 48.0, // Thay .h
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF4CAF50), // Hardcode AppColors.primaryColor
        ),
        child: child,
      )
    );
  }
}