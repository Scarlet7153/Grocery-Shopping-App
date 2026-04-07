import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_dimensions.dart';

/// Custom text field widget with consistent styling and validation
/// Supports password fields, validation, and role-specific theming
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final int? maxLines;
  final bool enabled;
  final Color? focusColor;
  final bool readOnly;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.maxLines = 1,
    this.enabled = true,
    this.focusColor,
    this.readOnly = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  String? get _displayError => widget.errorText ?? _validationError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) _buildLabel(),
        if (widget.label != null)
          const SizedBox(height: AppDimensions.spacingS),
        _buildTextField(),
        if (_displayError != null) _buildErrorText(),
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label!,
        style: AppTextStyles.inputLabel.copyWith(
          color: _getLabelColor(),
        ),
        children: widget.isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: AppTextStyles.inputLabel.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: _buildContainerDecoration(),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: (_) => null,
        onChanged: _onTextChanged,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        style: AppTextStyles.inputText,
        decoration: _buildInputDecoration(),
      ),
    );
  }

  void _onTextChanged(String value) {
    final error = widget.validator?.call(value);
    final newError = (error != null && error.isNotEmpty) ? error : null;
    if (newError != _validationError) {
      setState(() => _validationError = newError);
    }
    widget.onChanged?.call(value);
  }

  bool validate() {
    final value = widget.controller?.text ?? '';
    final error = widget.validator?.call(value);
    setState(() {
      _validationError = (error != null && error.isNotEmpty) ? error : null;
    });
    return _validationError == null;
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppDimensions.spacingS,
        left: AppDimensions.spacingM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppDimensions.iconS,
            color: AppColors.error,
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Expanded(
            child: Text(
              _displayError!,
              style: AppTextStyles.inputError,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      border: Border.all(
        color: _getBorderColor(),
        width: _isFocused ? 2.0 : 1.0,
      ),
      color: widget.enabled ? AppColors.surface : AppColors.surfaceVariant,
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: widget.prefixIcon != null
          ? Icon(
              widget.prefixIcon,
              color: _getPrefixIconColor(),
              size: AppDimensions.iconM,
            )
          : null,
      suffixIcon: _buildSuffixIcon(),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.prefixIcon != null
            ? AppDimensions.spacingM
            : AppDimensions.spacingL,
        vertical: widget.maxLines == 1
            ? AppDimensions.spacingM
            : AppDimensions.spacingL,
      ),
      isDense: true,
      errorText: null,
      errorStyle: const TextStyle(height: 0, fontSize: 0),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _getSuffixIconColor(),
          size: AppDimensions.iconM,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        splashRadius: AppDimensions.iconM,
      );
    }
    return widget.suffixWidget;
  }

  Color _getBorderColor() {
    if (_displayError != null) {
      return AppColors.error;
    }
    if (_isFocused) {
      return widget.focusColor ?? AppColors.storePrimary;
    }
    if (!widget.enabled) {
      return AppColors.textHint.withValues(alpha: 0.5);
    }
    return AppColors.border;
  }

  Color _getLabelColor() {
    if (_displayError != null) {
      return AppColors.error;
    }
    if (_isFocused) {
      return widget.focusColor ?? AppColors.storePrimary;
    }
    return AppColors.textSecondary;
  }

  Color _getPrefixIconColor() {
    if (_displayError != null) {
      return AppColors.error;
    }
    if (_isFocused) {
      return widget.focusColor ?? AppColors.storePrimary;
    }
    if (!widget.enabled) {
      return AppColors.textHint;
    }
    return AppColors.textSecondary;
  }

  Color _getSuffixIconColor() {
    if (_isFocused) {
      return widget.focusColor ?? AppColors.storePrimary;
    }
    return AppColors.textSecondary;
  }
}
