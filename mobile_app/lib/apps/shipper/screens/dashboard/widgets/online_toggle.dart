import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/theme/shipper_theme.dart';

class OnlineToggle extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const OnlineToggle(
      {super.key, required this.isOnline, required this.onToggle});

  @override
  State<OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends State<OnlineToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Trạng thái: ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isOnline)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final size = 24 + _pulseController.value * 12;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: ShipperTheme.primaryColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            Switch(
              value: widget.isOnline,
              activeThumbColor: ShipperTheme.primaryColor,
              onChanged: (_) => widget.onToggle(),
            ),
          ],
        ),
        Text(
          widget.isOnline ? 'Online' : 'Offline',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.isOnline
                        ? ShipperTheme.primaryColor
                        : Colors.grey[600],
                  ) ??
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: widget.isOnline
                    ? ShipperTheme.primaryColor
                    : Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
