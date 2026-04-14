import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/store_theme.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/logger.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/repository/auth_repository_impl.dart';
import '../../features/store/data/store_service.dart';
import '../../features/orders/data/order_service.dart';
import '../../features/products/data/product_service.dart';
import '../../features/review/data/review_service.dart';
import '../../features/products/data/category_service.dart';

import 'bloc/store_blocs.dart';
import 'bloc/store_language_cubit.dart';
import 'bloc/store_theme_cubit.dart';
import 'screens/auth/store_splash_screen.dart';
import 'screens/auth/store_login_screen.dart';
import 'screens/auth/store_register_screen.dart';
import 'screens/home/store_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.initialize();
  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient();
  runApp(StoreApp(prefs: prefs, apiClient: apiClient));
}

class StoreApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ApiClient apiClient;

  const StoreApp({super.key, required this.prefs, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(apiClient: apiClient, prefs: prefs),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) =>
                  AuthBloc(authRepository: context.read<AuthRepository>())),
          BlocProvider(create: (_) => StoreDashboardBloc(StoreService())),
          BlocProvider(create: (_) => StoreOrdersBloc(OrderService())),
          BlocProvider(create: (_) => StoreProductsBloc(ProductService())),
          BlocProvider(create: (_) => StoreReviewsBloc(ReviewService())),
          BlocProvider(create: (_) => StoreCategoriesBloc(CategoryService())),
          BlocProvider(create: (_) => StoreLanguageCubit()),
          BlocProvider(create: (_) => StoreThemeCubit()),
        ],
        child: BlocBuilder<StoreThemeCubit, StoreThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<StoreLanguageCubit, StoreLanguageState>(
              builder: (context, languageState) {
                return MaterialApp(
                  title: 'Đi Chợ Hộ - Chủ Cửa Hàng',
                  theme: StoreTheme.lightTheme,
                  darkTheme: StoreTheme.darkTheme,
                  themeMode: themeState.themeMode,
                  locale: languageState.locale,
                  supportedLocales: const [Locale('vi'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizationsDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const StoreSplashScreen(),
                  debugShowCheckedModeBanner: false,
                  onGenerateRoute: (settings) {
                    switch (settings.name) {
                      case '/store/login':
                        return MaterialPageRoute(
                            builder: (_) => const StoreLoginScreen());
                      case '/store/home':
                        return MaterialPageRoute(
                            builder: (_) => const StoreHomeScreen());
                      case '/store/register':
                        return MaterialPageRoute(
                            builder: (_) => const StoreRegisterScreen());
                      default:
                        return MaterialPageRoute(
                            builder: (_) => const StoreSplashScreen());
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
