import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

/// Reusable loading widget with different variants
class LoadingWidget extends StatelessWidget {
  // Constructors first
  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.type = LoadingType.circular,
  });
  
  /// Small loading indicator for buttons
  const LoadingWidget.small({
    super.key,
    this.message,
    this.color = AppColors.onPrimary,
  }) : size = 20,
       type = LoadingType.circular;
  
  /// Large loading indicator for full screen
  const LoadingWidget.large({
    super.key,
    this.message = 'Đang tải...',
    this.color,
  }) : size = 50,
       type = LoadingType.circular;

  // Fields after constructors
  final String? message;
  final double? size;
  final Color? color;
  final LoadingType type;

  @override
  Widget build(BuildContext context) {
    Widget loadingIndicator;
    
    switch (type) {
      case LoadingType.circular:
        loadingIndicator = SizedBox(
          width: size?.w ?? 24.w,
          height: size?.h ?? 24.h,
          child: CircularProgressIndicator(
            color: color ?? AppColors.primaryColor,
            strokeWidth: 2.w,
          ),
        );
        break;
      case LoadingType.linear:
        loadingIndicator = LinearProgressIndicator(
          color: color ?? AppColors.primaryColor,
          backgroundColor: AppColors.neutral90,
        );
        break;
    }
    
    if (message != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loadingIndicator,
          SizedBox(height: 16.h),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral50,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    return loadingIndicator;
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.child,
    required this.isLoading,
    super.key,
    this.message = 'Đang tải...',
    this.backgroundColor,
  });

  final Widget child;
  final bool isLoading;
  final String message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: LoadingWidget.large(message: message),
                ),
              ),
            ),
          ),
      ],
    );
}

enum LoadingType {
  circular,
  linear,
}
