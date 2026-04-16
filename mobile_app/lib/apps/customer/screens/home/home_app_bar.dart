import 'package:flutter/material.dart';

import '../../../../core/cart/cart_session.dart';
import '../../utils/customer_l10n.dart';

class HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HomeBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,

      backgroundColor: scheme.surface,

      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,

      type: BottomNavigationBarType.fixed,

      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: context.tr(vi: 'Trang chủ', en: 'Home'),
        ),

        BottomNavigationBarItem(
          icon: _CartBadgeIcon(),
          label: context.tr(vi: 'Giỏ hàng', en: 'Cart'),
        ),

        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt),
          label: context.tr(vi: 'Đơn hàng', en: 'Orders'),
        ),

        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: context.tr(vi: 'Hồ sơ', en: 'Profile'),
        ),
      ],
    );
  }
}

class _CartBadgeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartSession.items,
      builder: (context, items, child) {
        final totalQuantity = items.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart),
            if (totalQuantity > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      totalQuantity > 99 ? '99+' : totalQuantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
