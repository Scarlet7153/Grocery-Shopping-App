import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/customer_theme.dart';

import 'bloc/customer_auth_bloc.dart';
import 'repository/customer_auth_repository.dart';

import 'screens/auth/customer_splash_screen.dart';

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => CustomerAuthRepository(),
      child: BlocProvider(
        create: (context) =>
            CustomerAuthBloc(context.read<CustomerAuthRepository>()),
        child: MaterialApp(
          title: 'Đi Chợ Hộ - Khách Hàng',
          theme: CustomerTheme.lightTheme,
          darkTheme: CustomerTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          home: const CustomerSplashScreen(),
        ),
      ),
    );
  }
}
