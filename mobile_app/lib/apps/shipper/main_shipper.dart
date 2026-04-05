import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/shipper_theme.dart';
import 'bloc/shipper_auth_bloc.dart';
import 'repository/shipper_repository.dart';
import 'screens/auth/shipper_login_screen.dart';
import 'screens/auth/shipper_splash_screen.dart';
import 'screens/dashboard/shipper_dashboard_screen.dart';

void main() {
  runApp(const ShipperApp());
}

class ShipperApp extends StatelessWidget {
  const ShipperApp({super.key});

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
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    setState(() {
      _isAuthenticated = token != null && token.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return const ShipperSplashScreen();
    }

    return _isAuthenticated! ? const ShipperDashboardScreen() : const ShipperLoginScreen();
  }
}
