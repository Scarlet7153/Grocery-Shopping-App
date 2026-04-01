import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/shipper_theme.dart';
import 'bloc/shipper_auth_bloc.dart';
import 'repository/shipper_repository.dart';
import 'screens/auth/shipper_splash_screen.dart';
import 'screens/dashboard/shipper_dashboard_screen.dart';

void main() {
  runApp(const ShipperApp());
}

class ShipperApp extends StatelessWidget {
  const ShipperApp({super.key});

  // during development you can flip this to true and the app
  // will open the dashboard directly without going through auth.
  static const bool previewDashboard = true;

  @override
  Widget build(BuildContext context) {
    // provide repository and authentication bloc globally
    final repository = ShipperRepository();
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (_) => ShipperAuthBloc(repository: repository),
        child: MaterialApp(
          title: 'Đi Chợ Hộ - Shipper',
          theme: ShipperTheme.lightTheme,
          home: previewDashboard
              ? const ShipperDashboardScreen.preview()
              : const ShipperSplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}