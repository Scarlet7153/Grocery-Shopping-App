import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../dashboard/store_dashboard_screen.dart';
import '../orders/store_orders_screen.dart';
import '../products/store_products_screen.dart';
import '../reviews/store_reviews_screen.dart';
import '../profile/store_profile_screen.dart';
import '../auth/store_login_screen.dart';

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});
  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    String tr({required String vi, required String en}) =>
        localizations?.byLocale(vi: vi, en: en) ?? vi;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthSessionExpired) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StoreLoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            StoreDashboardScreen(
              onViewAllOrders: () => setState(() => _currentIndex = 1),
            ),
            const StoreOrdersScreen(),
            const StoreProductsScreen(),
            const StoreReviewsScreen(),
            const StoreProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard),
                label: tr(vi: 'Tổng quan', en: 'Dashboard')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.receipt), label: tr(vi: 'Đơn', en: 'Orders')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.inventory),
                label: tr(vi: 'Sản phẩm', en: 'Products')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.star),
                label: tr(vi: 'Đánh giá', en: 'Reviews')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.store), label: tr(vi: 'Cửa hàng', en: 'Store')),
          ],
        ),
      ),
    );
  }
}
