import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Card widget for selecting user role in role selection screen
class RoleSelectionCard extends StatefulWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  const RoleSelectionCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  @override
  State<RoleSelectionCard> createState() => _RoleSelectionCardState();
}

class _RoleSelectionCardState extends State<RoleSelectionCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _selectionController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntryAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationSlow),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationNormal),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeInOut),
    );
  }

  void _startEntryAnimation() {
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(RoleSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: _buildCard()),
        );
      },
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: AppDimensions.animationNormal,
            ),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: _buildCardDecoration(),
            child: _buildCardContent(),
          ),
        );
      },
    );
  }

  BoxDecoration _buildCardDecoration() {
    final baseColor = widget.role.primaryColor;
    final selectionProgress = _selectionAnimation.value;

    return BoxDecoration(
      color: widget.isSelected
          ? baseColor.withValues(alpha: 0.1 + 0.05 * selectionProgress)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      border: Border.all(
        color: widget.isSelected
            ? baseColor.withValues(alpha: 0.8 + 0.2 * selectionProgress)
            : AppColors.border,
        width: widget.isSelected ? 2.0 : 1.0,
      ),
      boxShadow: [
        if (widget.isSelected) ...[
          BoxShadow(
            color: baseColor.withValues(alpha: 0.2 * selectionProgress),
            blurRadius: 12.0 * selectionProgress,
            offset: Offset(0, 6.0 * selectionProgress),
          ),
        ] else ...[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ],
    );
  }

  Widget _buildCardContent() {
    return Row(
      children: [
        _buildRoleIcon(),
        const SizedBox(width: AppDimensions.spacingL),
        Expanded(child: _buildRoleInfo()),
        _buildSelectionIndicator(),
      ],
    );
  }

  Widget _buildRoleIcon() {
    final baseColor = widget.role.primaryColor;
    final selectionProgress = _selectionAnimation.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: AppDimensions.animationNormal),
      width: AppDimensions.iconXl + 8,
      height: AppDimensions.iconXl + 8,
      decoration: BoxDecoration(
        color: widget.isSelected
            ? baseColor.withValues(alpha: 0.2 + 0.1 * selectionProgress)
            : baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Icon(
        widget.isSelected ? widget.role.iconFilled : widget.role.icon,
        size: AppDimensions.iconL,
        color: widget.isSelected ? baseColor : baseColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildRoleInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.role.displayName,
          style: AppTextStyles.titleMedium.copyWith(
            color: widget.isSelected
                ? widget.role.primaryColor
                : AppColors.textPrimary,
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          widget.role.description,
          style: AppTextStyles.bodySmall.copyWith(
            color: widget.isSelected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSelectionIndicator() {
    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        if (!widget.isSelected && _selectionAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }

        return Transform.scale(
          scale: _selectionAnimation.value,
          child: Container(
            width: AppDimensions.iconM,
            height: AppDimensions.iconM,
            decoration: BoxDecoration(
              color: widget.role.primaryColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: const Icon(
              Icons.check,
              size: AppDimensions.iconS,
              color: AppColors.textOnDark,
            ),
          ),
        );
      },
    );
  }
}
