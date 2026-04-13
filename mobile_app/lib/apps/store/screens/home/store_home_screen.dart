import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../block/store_dashboard_bloc.dart';
import '../../block/store_orders_bloc.dart';
import '../../block/store_products_bloc.dart';
import '../dashboard/store_dashboard_screen.dart';
import '../orders/store_orders_screen.dart';
import '../products/store_products_screen.dart';
import '../chat/store_chat_screen.dart';
import '../profile/store_profile_screen.dart';
import '../../widgets/scale_on_tap.dart';

const Color _kPrimary = Color(0xFF00B14F);

class StoreHomeScreen extends StatefulWidget {
  final String token;

  const StoreHomeScreen({super.key, required this.token});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  int currentIndex = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      StoreDashboardScreen(token: widget.token),
      const StoreOrdersScreen(),
      StoreProductsScreen(token: widget.token),
      const StoreChatScreen(),
      StoreProfileScreen(token: widget.token),
    ];
  }

  void _selectTab(int index) {
    setState(() => currentIndex = index);
    if (!mounted) return;
    final t = widget.token;
    switch (index) {
      case 0:
        context.read<StoreDashboardBloc>().add(
              LoadStoreDashboard(t, showLoading: false),
            );
        context.read<StoreOrdersBloc>().add(LoadStoreOrders());
        context.read<StoreProductsBloc>().add(LoadStoreProducts(token: t));
        break;
      case 1:
        context.read<StoreOrdersBloc>().add(LoadStoreOrders());
        break;
      case 2:
        context.read<StoreProductsBloc>().add(LoadStoreProducts(token: t));
        break;
      case 4:
        context.read<StoreDashboardBloc>().add(
              LoadStoreDashboard(t, showLoading: false),
            );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ScaleOnTap(
                  onTap: () => _selectTab(0),
                  child: _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Tổng quan',
                    isSelected: currentIndex == 0,
                    onTap: () => _selectTab(0),
                  ),
                ),
                ScaleOnTap(
                  onTap: () => _selectTab(1),
                  child: _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Đơn',
                    isSelected: currentIndex == 1,
                    onTap: () => _selectTab(1),
                  ),
                ),
                ScaleOnTap(
                  onTap: () => _selectTab(2),
                  child: _NavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Sản phẩm',
                    isSelected: currentIndex == 2,
                    onTap: () => _selectTab(2),
                  ),
                ),
                ScaleOnTap(
                  onTap: () => _selectTab(3),
                  child: _NavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    isSelected: currentIndex == 3,
                    onTap: () => _selectTab(3),
                    unreadCount: 2,
                  ),
                ),
                ScaleOnTap(
                  onTap: () => _selectTab(4),
                  child: _NavItem(
                    icon: Icons.store_rounded,
                    label: 'Cửa hàng',
                    isSelected: currentIndex == 4,
                    onTap: () => _selectTab(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? unreadCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = unreadCount != null && unreadCount! > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? _kPrimary : Colors.grey.shade500,
                ),
                if (showBadge)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount! > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              showBadge ? '$label ($unreadCount)' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _kPrimary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
