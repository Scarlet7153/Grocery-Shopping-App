import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class OnlineToggle extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  State<OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends State<OnlineToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  String _tr(BuildContext context, String vi, String en) {
    final l = AppLocalizations.of(context) ??
        AppLocalizations(Localizations.localeOf(context));
    return l.byLocale(vi: vi, en: en);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant OnlineToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isOnline && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOnline = widget.isOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? ShipperTheme.primaryColor.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isOnline)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) {
                          final size = 14 + _pulseController.value * 8;
                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: ShipperTheme.primaryColor.withValues(
                                alpha: 0.25,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? ShipperTheme.primaryColor
                            : scheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tr(context, 'Trạng thái', 'Status'),
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      isOnline
                          ? _tr(context, 'Trực tuyến', 'Online')
                          : _tr(context, 'Ngoại tuyến', 'Offline'),
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isOnline
                                ? ShipperTheme.primaryColor
                                : scheme.onSurface,
                          ) ??
                          TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isOnline
                                ? ShipperTheme.primaryColor
                                : scheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnline,
            activeThumbColor: ShipperTheme.primaryColor,
            onChanged: (_) => widget.onToggle(),
          ),
        ],
      ),
    );
  }
}
