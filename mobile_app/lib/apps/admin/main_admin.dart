// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../core/config/app_config.dart';
// import '../../core/enums/user_role.dart';
// import '../../core/theme/admin_theme.dart';
// import '../../core/network/api_client.dart';
// import '../../core/utils/logger.dart'; // Thêm import logger

// import '../../features/auth/bloc/auth_bloc.dart';
// import '../../features/auth/repository/auth_repository_impl.dart';

// import '../../features/auth/presentation/screens/login_screen.dart';
// import '../../features/auth/presentation/screens/otp_screen.dart';
// import '../../features/auth/presentation/screens/admin_dashboard_screen.dart';
// import 'screens/auth/admin_splash_screen.dart'; 

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Khởi tạo Logger trước tiên để tránh lỗi LateInitializationError
//   // Nếu hàm khởi tạo trong file logger.dart của bạn tên khác (vd: configure()), hãy đổi lại cho đúng.
//   AppLogger.initialize();
  
//   // Khởi tạo SharedPreferences trước khi chạy App
//   final prefs = await SharedPreferences.getInstance();
  
//   // Truyền prefs vào AdminApp
//   runApp(AdminApp(prefs: prefs));
// }

// class AdminApp extends StatelessWidget {
//   final SharedPreferences prefs;
  
//   const AdminApp({super.key, required this.prefs});

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         // Khởi tạo và cung cấp AuthBloc cho toàn bộ ứng dụng
//         BlocProvider<AuthBloc>(
//           create: (context) => AuthBloc(
//             authRepository: AuthRepositoryImpl(
//               apiClient: ApiClient(),
//               prefs: prefs,
//             ),
//           ),
//         ),
//       ],
//       child: ScreenUtilInit(
//         designSize: const Size(375, 812),
//         minTextAdapt: true,
//         splitScreenMode: true,
//         builder: (context, child) => MaterialApp(
//           title: AppConfig.appName, 
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             primaryColor: AdminTheme.primaryColor, 
//             useMaterial3: true,
//             colorScheme: ColorScheme.fromSeed(seedColor: AdminTheme.primaryColor),
//           ),
//           initialRoute: '/',
//           routes: {
//             '/': (context) => const AdminSplashScreen(), 
//             '/login': (context) => const LoginScreen(userRole: UserRole.admin),
//             '/otp-verification': (context) {
//               final args = ModalRoute.of(context)?.settings.arguments as String?;
//               return OtpScreen(identifier: args ?? 'admin');
//             },
//             '/admin-dashboard': (context) => const AdminDashboardScreen(),
//           },
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/config/app_config.dart';
import '../../core/enums/user_role.dart';
import '../../core/theme/admin_theme.dart';
import '../../core/api/api_client.dart' as global_api;
import '../../core/utils/logger.dart';
import '../../core/utils/app_localizations.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository_impl.dart';
import '../../features/admin/bloc/settings_bloc.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/admin_dashboard_screen.dart';
import 'screens/auth/admin_splash_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.initialize();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(AdminApp(prefs: prefs));
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
                '/otp-verification': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as String?;
                  return OtpScreen(identifier: args ?? 'admin');
                },
                '/admin-dashboard': (context) => const AdminDashboardScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}
