import 'package:flutter/material.dart';

class CustomerStateView extends StatelessWidget {
  const CustomerStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.isError = false,
  });

  const CustomerStateView.loading({
    super.key,
    this.title = 'Đang tải dữ liệu',
    this.message = 'Vui lòng chờ trong giây lát...',
    this.compact = false,
  }) : icon = const SizedBox(
         width: 26,
         height: 26,
         child: CircularProgressIndicator(strokeWidth: 2.4),
       ),
       actionLabel = null,
    onAction = null,
    isError = false;

  const CustomerStateView.empty({
    super.key,
    this.title = 'Chưa có dữ liệu',
    this.message = 'Hiện chưa có thông tin để hiển thị.',
    this.compact = false,
    this.actionLabel,
    this.onAction,
    Widget? icon,
  }) : icon = icon ?? const Icon(Icons.inbox_rounded, size: 54),
       isError = false;

  const CustomerStateView.error({
    super.key,
    this.title = 'Đã xảy ra lỗi',
    this.message = 'Không thể tải dữ liệu. Vui lòng thử lại.',
    this.compact = false,
    this.actionLabel = 'Thử lại',
    this.onAction,
    Widget? icon,
  }) : icon = icon ?? const Icon(Icons.cloud_off_rounded, size: 54),
       isError = true;

  final Widget icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontal = compact ? 20.0 : 28.0;
    final vertical = compact ? 16.0 : 24.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: isError ? scheme.error : scheme.onSurfaceVariant,
                ),
                child: icon,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
