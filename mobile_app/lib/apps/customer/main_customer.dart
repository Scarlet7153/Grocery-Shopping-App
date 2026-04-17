import 'dart:async';

import 'package:app_links/app_links.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/cart/cart_session.dart';
import '../../core/config/environment.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/customer_theme.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/log_silencer.dart';
import '../../shared/widgets/snackbar_utils.dart';

import 'bloc/customer_auth_bloc.dart';
import 'bloc/customer_language_cubit.dart';
import 'bloc/customer_theme_cubit.dart';
import 'repository/customer_auth_repository.dart';
import 'screens/auth/customer_splash_screen.dart';
import 'screens/cart/customer_payment_tracking_screen.dart';
import 'screens/orders/customer_order_detail_screen.dart';
import 'shared/customer_payment_method.dart';
import '../../features/notification/bloc/notification_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.load();
  await CartSession.load();
  LogSilencer.run(() => runApp(const CustomerApp()));
}

class CustomerApp extends StatefulWidget {
  const CustomerApp({super.key});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinkListener() async {
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      _handleIncomingUri(initialUri);
    } catch (_) {
      // ignore malformed initial uri
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingUri,
      onError: (_) {
        // ignore errors from invalid incoming links
      },
    );
  }

  void _handleIncomingUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme == 'dichohho' &&
        uri.host == 'payment' &&
        uri.path == '/callback') {
      final paymentIdString =
          uri.queryParameters['extraData'] ?? uri.queryParameters['paymentId'];
      final orderIdString = uri.queryParameters['orderId'];
      final paymentId = int.tryParse(paymentIdString ?? '');
      final orderId = int.tryParse(orderIdString ?? '');
      final resultCode = uri.queryParameters['resultCode'] ?? '';
      final transId = uri.queryParameters['transId'];
      final isSuccess = resultCode == '0';

      if (paymentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _reportPaymentResult(paymentId, isSuccess, transId);
          if (!mounted) return;
          if (isSuccess && orderId != null) {
            await Future.delayed(const Duration(seconds: 1));
            if (_navigatorKey.currentContext != null) {
              Navigator.of(_navigatorKey.currentContext!).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerOrderDetailScreen(orderId: orderId.toString()),
                ),
              );
            }
          } else {
            _navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => CustomerPaymentTrackingScreen(
                orderId: orderId,
                paymentId: paymentId,
                redirectUrl: '',
                paymentMethod: CustomerPaymentMethod.momo,
              ),
            ));
          }
        });
      }
    }
  }

  Future<void> _reportPaymentResult(
      int paymentId, bool success, String? transId) async {
    try {
      await ApiClient.dio.post(
        '/payments/report-result',
        data: {
          'paymentId': paymentId,
          'success': success,
          if (transId != null) 'transactionCode': transId,
        },
      );
      if (_navigatorKey.currentContext != null) {
        SnackBarUtils.showSuccess(
          context: _navigatorKey.currentContext!,
          message: success
              ? 'Thanh toán MoMo thành công'
              : 'Thanh toán MoMo thất bại',
        );
      }
    } catch (e) {
      debugPrint('Failed to report payment result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => CustomerAuthRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                CustomerAuthBloc(context.read<CustomerAuthRepository>()),
          ),
          BlocProvider(create: (_) => CustomerThemeCubit()),
          BlocProvider(create: (_) => CustomerLanguageCubit()),
          BlocProvider(create: (_) => NotificationBloc()..add(LoadNotifications())),
        ],
        child: BlocBuilder<CustomerThemeCubit, CustomerThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<CustomerLanguageCubit, CustomerLanguageState>(
              builder: (context, languageState) {
                return MaterialApp(
                  navigatorKey: _navigatorKey,
                  title: 'Grocery Shopping - Customer',
                  theme: CustomerTheme.lightTheme,
                  darkTheme: CustomerTheme.darkTheme,
                  themeMode: themeState.themeMode,
                  debugShowCheckedModeBanner: false,
                  locale: languageState.locale,
                  supportedLocales: const [Locale('vi'), Locale('en')],
                  localizationsDelegates: const [
                    AppLocalizationsDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const CustomerSplashScreen(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
