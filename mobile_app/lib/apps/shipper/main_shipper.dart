import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/shipper_theme.dart';
import 'bloc/shipper_auth_bloc.dart';
import 'bloc/shipper_dashboard_bloc.dart';
import 'repository/shipper_repository.dart';
import 'screens/auth/shipper_splash_screen.dart';

void main() {
  runApp(const ShipperApp());
}

class ShipperApp extends StatelessWidget {
  const ShipperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ShipperRepository();
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ShipperAuthBloc(repository: repository)),
          BlocProvider(
            create: (_) => ShipperDashboardBloc(repository: repository),
          ),
        ],
        child: MaterialApp(
          title: 'Đi Chợ Hộ - Shipper',
          theme: ShipperTheme.lightTheme,
          home: const ShipperSplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
