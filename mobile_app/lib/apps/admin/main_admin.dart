import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/config/app_config.dart';
import '../../core/config/environment.dart';
import '../../core/enums/user_role.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/api/api_client.dart' as global_api;
import '../../core/utils/logger.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/log_silencer.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository_impl.dart';
import '../../features/admin/bloc/settings_bloc.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/admin_dashboard_screen.dart';
import 'screens/auth/admin_splash_screen.dart'; 

void main() async {
  await LogSilencer.runAsync(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Environment.load();
    AppLogger.initialize();
    final prefs = await SharedPreferences.getInstance();
    runApp(AdminApp(prefs: prefs));
  });
}

class AdminApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const AdminApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(
              apiClient: global_api.ApiClient(),
              prefs: prefs,
            ),
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(prefs: prefs),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => MaterialApp(
              title: AppConfig.appName, 
              debugShowCheckedModeBanner: false,
              theme: AdminTheme.lightTheme,
              darkTheme: AdminTheme.darkTheme,
              themeMode: settingsState.themeMode,
              locale: settingsState.locale,
              supportedLocales: const [Locale('vi'), Locale('en')],
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: '/',
              routes: {
                '/': (context) => const AdminSplashScreen(), 
                '/login': (context) => const LoginScreen(userRole: UserRole.admin),
                '/admin-dashboard': (context) => const AdminDashboardScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
