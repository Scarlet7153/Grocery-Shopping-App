import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/store_theme.dart';
import '../../features/orders/data/order_service.dart';
import '../../features/products/data/product_service.dart';

import 'screens/auth/store_splash_screen.dart';
import 'repository/store_repository.dart';
import 'block/store_auth_bloc.dart';
import 'block/store_dashboard_bloc.dart';
import 'block/store_orders_bloc.dart';
import 'block/store_products_bloc.dart';

void main() {
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StoreAuthBloc(StoreRepository())),
        BlocProvider(create: (_) => StoreDashboardBloc(StoreRepository())),
        BlocProvider(create: (_) => StoreProductsBloc(ProductService())),
        BlocProvider(create: (_) => StoreOrdersBloc(OrderService())),
      ],
      child: MaterialApp(
        title: 'Đi Chợ Hộ - Chủ Cửa Hàng',
        theme: StoreTheme.lightTheme,
        home: const StoreSplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
