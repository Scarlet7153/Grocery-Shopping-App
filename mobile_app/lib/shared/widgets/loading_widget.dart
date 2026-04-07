import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';  // Tạm thời comment
// import '../../core/theme/app_colors.dart';  // Không cần thiết, dùng hardcode

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  const LoadingWidget.small({
    super.key,
    this.message,
    this.color = Colors.white,
  }) : size = 20;

  const LoadingWidget.large({
    super.key,
    this.message = 'Đang tải...',
    this.color,
  }) : size = 50;

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = SizedBox(
      width: size ?? 24.0, // Thay .w bằng .0
      height: size ?? 24.0, // Thay .h bằng .0
      child: CircularProgressIndicator(
        color:
            color ?? const Color(0xFF4CAF50), // Hardcode AppColors.primaryColor
        strokeWidth: 2.0, // Thay .w bằng .0
      ),
    );

    if (message != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loadingIndicator,
          const SizedBox(height: 16.0), // Thay .h bằng .0
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loadingIndicator;
  }
}
