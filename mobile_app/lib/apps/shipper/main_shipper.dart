import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/theme/shipper_theme.dart';
import '../../core/utils/app_localizations.dart';
import 'bloc/shipper_auth_bloc.dart';
import 'bloc/shipper_dashboard_bloc.dart';
import 'bloc/shipper_language_cubit.dart';
import 'bloc/shipper_theme_cubit.dart';
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
          BlocProvider(create: (_) => ShipperThemeCubit()),
          BlocProvider(create: (_) => ShipperLanguageCubit()),
        ],
        child: BlocBuilder<ShipperThemeCubit, ShipperThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<ShipperLanguageCubit, ShipperLanguageState>(
              builder: (context, languageState) {
                return MaterialApp(
                  title: 'Đi Chợ Hộ - Shipper',
                  theme: ShipperTheme.lightTheme,
                  darkTheme: ShipperTheme.darkTheme,
                  themeMode: themeState.themeMode,
                  locale: languageState.locale,
                  supportedLocales: const [Locale('vi'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizationsDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const ShipperSplashScreen(),
                  debugShowCheckedModeBanner: false,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
