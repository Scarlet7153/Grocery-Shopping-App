import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../loading_widget.dart';

/// Button types for different visual styles
enum ButtonType {
  primary,
  secondary,
  outline,
  ghost,
  text,
}

/// Button sizes for different contexts
enum ButtonSize {
  small,
  medium,
  large,
}

/// Custom button widget with consistent styling across the app
/// Supports multiple types, sizes, and loading states
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final Color? customColor;
  final Color? textColor;
  final double? width;
  final IconData? icon;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.customColor,
    this.textColor,
    this.width,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: _getButtonHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (type) {
      case ButtonType.primary:
        return _buildElevatedButton();
      case ButtonType.secondary:
        return _buildElevatedButton(isSecondary: true);
      case ButtonType.outline:
        return _buildOutlinedButton();
      case ButtonType.ghost:
        return _buildTextButton(isGhost: true);
      case ButtonType.text:
        return _buildTextButton();
    }
  }

  Widget _buildElevatedButton({bool isSecondary = false}) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(isSecondary: isSecondary),
        foregroundColor: _getForegroundColor(),
        elevation: _getElevation(),
        shadowColor: _getShadowColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
        padding: _getPadding(),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _getOutlineColor(),
        side: BorderSide(
          color: isLoading ? AppColors.textHint : _getOutlineColor(),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
        padding: _getPadding(),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildTextButton({bool isGhost = false}) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _getTextButtonColor(),
        backgroundColor:
            isGhost ? _getBackgroundColor().withValues(alpha: 0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
        padding: _getPadding(),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const LoadingWidget.small();
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _getIconSize()),
          SizedBox(width: _getIconSpacing()),
          Text(text, style: _getTextStyle()),
        ],
      );
    }

    return Text(text, style: _getTextStyle());
  }

  // Helper Methods for Styling

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightSmall;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightMedium;
      case ButtonSize.large:
        return AppDimensions.buttonHeightLarge;
    }
  }

  Color _getBackgroundColor({bool isSecondary = false}) {
    if (customColor != null) return customColor!;

    if (isSecondary) {
      return AppColors.warning; // Use warning color as secondary
    }

    return AppColors.storePrimary; // Default to store green
  }

  Color _getForegroundColor() {
    if (textColor != null) return textColor!;
    return AppColors.textOnDark;
  }

  Color _getOutlineColor() {
    if (customColor != null) return customColor!;
    return AppColors.storePrimary;
  }

  Color _getTextButtonColor() {
    if (customColor != null) return customColor!;
    return AppColors.storePrimary;
  }

  double _getElevation() {
    return isLoading
        ? AppDimensions.elevationNone
        : AppDimensions.elevationMedium;
  }

  Color _getShadowColor() {
    return _getBackgroundColor().withValues(alpha: 0.1);
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.radiusS;
      case ButtonSize.medium:
      case ButtonSize.large:
        return AppDimensions.radiusM;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontal,
          vertical: AppDimensions.buttonPaddingVertical,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing3Xl,
          vertical: AppDimensions.spacingL,
        );
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = switch (size) {
      ButtonSize.small => AppTextStyles.buttonSmall,
      ButtonSize.medium => AppTextStyles.buttonMedium,
      ButtonSize.large => AppTextStyles.buttonLarge,
    };

    Color finalTextColor;
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        finalTextColor = _getForegroundColor();
        break;
      case ButtonType.outline:
      case ButtonType.ghost:
      case ButtonType.text:
        finalTextColor = _getTextButtonColor();
        break;
    }

    return baseStyle.copyWith(color: finalTextColor);
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.iconS;
      case ButtonSize.medium:
        return AppDimensions.iconM;
      case ButtonSize.large:
        return AppDimensions.iconM;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.spacingS;
      case ButtonSize.medium:
      case ButtonSize.large:
        return AppDimensions.spacingM;
    }
  }
}
